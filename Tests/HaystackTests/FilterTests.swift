import Haystack
import Testing

struct FilterTests {
    @Test func identity() throws {
        try #expect(FilterFactory.has("a").equals(FilterFactory.has("a")))
        try #expect(!FilterFactory.has("a").equals(FilterFactory.has("b")))
    }

    @Test func basics() throws {
        try verifyParse("x", FilterFactory.has("x"))
        try verifyParse("foo", FilterFactory.has("foo"))
        try verifyParse("fooBar", FilterFactory.has("fooBar"))
        try verifyParse("foo7Bar", FilterFactory.has("foo7Bar"))
        try verifyParse("foo_bar->a", FilterFactory.has("foo_bar->a"))
        try verifyParse("a->b->c", FilterFactory.has("a->b->c"))
        try verifyParse("not foo", FilterFactory.missing("foo"))
    }

    @Test func zincOnlyLiteralsDontWork() throws {
        #expect(throws: (any Error).self) { try FilterFactory.make("x==T") }
        #expect(throws: (any Error).self) { try FilterFactory.make("x==F") }
        #expect(throws: (any Error).self) { try FilterFactory.make("x==F") }
    }

    @Test func bool() throws {
        try verifyParse("x->y==true", FilterFactory.eq("x->y", true))
        try verifyParse("x->y!=false", FilterFactory.ne("x->y", false))
    }

    @Test func str() throws {
        try verifyParse("x==\"hi\"", FilterFactory.eq("x", "hi"))
        try verifyParse("x!=\"\\\"hi\\\"\"", FilterFactory.ne("x", "\"hi\""))
        try verifyParse("x==\"_\\uabcd_\\n_\"", FilterFactory.eq("x", "_\u{abcd}_\n_"))
    }

    @Test func uri() throws {
        try verifyParse("ref==`http://foo/?bar`", FilterFactory.eq("ref", Uri("http://foo/?bar")))
        try verifyParse("ref->x==`file name`", FilterFactory.eq("ref->x", Uri("file name")))
        try verifyParse("ref == `foo bar`", FilterFactory.eq("ref", Uri("foo bar")))
    }

    @Test func int() throws {
        try verifyParse("num < 4", FilterFactory.lt("num", Number(4)))
        try verifyParse("num <= -99", FilterFactory.le("num", Number(-99)))
    }

    @Test func float() throws {
        try verifyParse("num < 4.0", FilterFactory.lt("num", Number(4.0)))
        try verifyParse("num <= -9.6", FilterFactory.le("num", Number(-9.6)))
        try verifyParse("num > 400000", FilterFactory.gt("num", Number(4e5)))
        try verifyParse("num >= 16000", FilterFactory.ge("num", Number(1.6e+4)))
        try verifyParse("num >= 2.16", FilterFactory.ge("num", Number(2.16)))
    }

    @Test func unit() throws {
        try verifyParse("dur < 5ns", FilterFactory.lt("dur", Number(5, unit: "ns")))
        try verifyParse("dur < 10kg", FilterFactory.lt("dur", Number(10, unit: "kg")))
        try verifyParse("dur < -9sec", FilterFactory.lt("dur", Number(-9, unit: "sec")))
        try verifyParse("dur < 2.5hr", FilterFactory.lt("dur", Number(2.5, unit: "hr")))
    }

    @Test func dateTime() throws {
        try verifyParse("foo < 2009-10-30", FilterFactory.lt("foo", Date("2009-10-30")))
        try verifyParse("foo < 08:30:00", FilterFactory.lt("foo", Time("08:30:00")))
        try verifyParse("foo < 13:00:00", FilterFactory.lt("foo", Time("13:00:00")))
    }

    @Test func ref() throws {
        try verifyParse("author == @xyz", FilterFactory.eq("author", Ref("xyz")))
        try verifyParse("author==@xyz:foo.bar", FilterFactory.eq("author", Ref("xyz:foo.bar")))
    }

    @Test func and() throws {
        try verifyParse("a and b", FilterFactory.has("a").and(FilterFactory.has("b")))
        try verifyParse("a and b and c == 3", FilterFactory.has("a").and(FilterFactory.has("b").and(FilterFactory.eq("c", Number(3)))))
    }

    @Test func or() throws {
        try verifyParse("a or b", FilterFactory.has("a").or(FilterFactory.has("b")))
        try verifyParse("a or b or c == 3", FilterFactory.has("a").or(FilterFactory.has("b").or(FilterFactory.eq("c", Number(3)))))
    }

    @Test func parens() throws {
        try verifyParse("(a)", FilterFactory.has("a"))
        try verifyParse("(a) and (b)", FilterFactory.has("a").and(FilterFactory.has("b")))
        try verifyParse("( a )  and  ( b ) ", FilterFactory.has("a").and(FilterFactory.has("b")))
        try verifyParse("(a or b) or (c == 3)", FilterFactory.has("a").or(FilterFactory.has("b")).or(FilterFactory.eq("c", Number(3))))
    }

    @Test func combo() throws {
        let isA = try FilterFactory.has("a")
        let isB = try FilterFactory.has("b")
        let isC = try FilterFactory.has("c")
        let isD = try FilterFactory.has("d")
        try verifyParse("a and b or c", (isA.and(isB)).or(isC))
        try verifyParse("a or b and c", isA.or(isB.and(isC)))
        try verifyParse("a and b or c and d", (isA.and(isB)).or(isC.and(isD)))
        try verifyParse("(a and (b or c)) and d", isA.and(isB.or(isC)).and(isD))
        try verifyParse("(a or (b and c)) or d", isA.or(isB.and(isC)).or(isD))
    }

    func verifyParse(_ s: String, _ expected: any Filter) throws {
        let actual = try FilterFactory.make(s)
        #expect(actual.equals(expected))
    }

    @Test func include() throws {
        let a: Dict = try [
            "dis": "a",
            "num": Number(10),
            "date": Date(year: 2016, month: 1, day: 1),
            "foo": "baz",
        ]

        let b: Dict = try [
            "dis": "b",
            "num": Number(20),
            "date": Date(year: 2016, month: 1, day: 2),
            "foo": Number(12),
            "ref": Ref("a"),
        ]

        let c: Dict = try [
            "dis": "c",
            "num": Number(30),
            "date": Date(year: 2016, month: 1, day: 3),
            "foo": Number(13),
            "ref": Ref("b"),
            "thru": "c",
        ]

        let d: Dict = try [
            "dis": "d",
            "num": Number(30),
            "date": Date(year: 2016, month: 1, day: 3),
            "ref": Ref("c"),
        ]

        let nested: Dict = [
            "thru": "e",
        ]
        let e: Dict = try [
            "dis": "e",
            "num": Number(40),
            "date": Date(year: 2016, month: 1, day: 6),
            "ref": nested,
        ]

        let db = [
            "a": a,
            "b": b,
            "c": c,
            "d": d,
            "e": e,
        ]

        try verifyInclude(db, "ref->thru", "d,e")

        try verifyInclude(db, "dis", "a,b,c,d,e")
        try verifyInclude(db, "foo", "a,b,c")

        try verifyInclude(db, "not dis", "")
        try verifyInclude(db, "not foo", "d,e")

        try verifyInclude(db, "dis == \"c\"", "c")
        try verifyInclude(db, "num == 30", "c,d")
        try verifyInclude(db, "date==2016-01-02", "b")
        try verifyInclude(db, "foo==12", "b")

        try verifyInclude(db, "dis != \"c\"", "a,b,d,e")
        try verifyInclude(db, "num != 30", "a,b,e")
        try verifyInclude(db, "date != 2016-01-02", "a,c,d,e")
        try verifyInclude(db, "foo != 13", "a,b")

        try verifyInclude(db, "dis < \"c\"", "a,b")
        try verifyInclude(db, "num < 20", "a")
        try verifyInclude(db, "date < 2016-01-04", "a,b,c,d")
        try verifyInclude(db, "foo < 13", "b")
        try verifyInclude(db, "foo < \"c\"", "a")

        try verifyInclude(db, "dis <= \"c\"", "a,b,c")
        try verifyInclude(db, "num <= 20", "a,b")
        try verifyInclude(db, "date <= 2016-01-02", "a,b")
        try verifyInclude(db, "foo <= 13", "b,c")
        try verifyInclude(db, "foo <= \"baz\"", "a")

        try verifyInclude(db, "dis > \"c\"", "d,e")
        try verifyInclude(db, "num > 20", "c,d,e")
        try verifyInclude(db, "date > 2016-01-02", "c,d,e")
        try verifyInclude(db, "foo > 12", "c")
        try verifyInclude(db, "foo > \"a\"", "a")

        try verifyInclude(db, "dis >= \"c\"", "c,d,e")
        try verifyInclude(db, "num >= 20", "b,c,d,e")
        try verifyInclude(db, "date >= 2016-01-02", "b,c,d,e")
        try verifyInclude(db, "foo >= 12", "b,c")
        try verifyInclude(db, "foo >= \"baz\"", "a")

        try verifyInclude(db, "dis==\"c\" or num == 30", "c,d")
        try verifyInclude(db, "dis==\"c\" and num == 30", "c")
        try verifyInclude(db, "dis==\"c\" or num == 30 or dis==\"b\"", "b,c,d")
        try verifyInclude(db, "dis==\"c\" and num == 30 and foo==13", "c")
        try verifyInclude(db, "dis==\"c\" and num == 30 and foo==12", "")
        try verifyInclude(db, "dis==\"c\" and num == 30 or foo==12", "b,c")
        try verifyInclude(db, "(dis==\"c\" or num == 30) and not foo", "d")
        try verifyInclude(db, "(num == 30 and foo) or (num <= 10)", "a,c")

        try verifyInclude(db, "ref->dis == \"a\"", "b")
        try verifyInclude(db, "ref->ref->dis == \"a\"", "c")
        try verifyInclude(db, "ref->ref->ref->dis == \"a\"", "d")
        try verifyInclude(db, "ref->num <= 20", "b,c")
        try verifyInclude(db, "ref->thru", "d,e")
        try verifyInclude(db, "ref->thru == \"e\"", "e")
    }

    func verifyInclude(_ map: [String: Dict], _ query: String, _ expected: String) throws {
        let q = try FilterFactory.make(query)

        var actual = ""
        for id in ["a", "b", "c", "d", "e"] {
            if
                let dict = map[id],
                try q.include(
                    dict: dict,
                    pather: { ref in
                        map[ref]
                    }
                )
            {
                if actual.count > 0 {
                    actual += ","
                }
                actual += id
            }
        }
        #expect(actual == expected)
    }

    @Test func path() throws {
        // single name
        var path = try Path.make(path: "foo")
        #expect(path.count == 1)
        #expect(path[0] == "foo")
        #expect(path.description == "foo")
        #expect(try path == Path.make(path: "foo"))

        // two names
        path = try Path.make(path: "foo->bar")
        #expect(path.count == 2)
        #expect(path[0] == "foo")
        #expect(path[1] == "bar")
        #expect(path.description == "foo->bar")
        #expect(try path == Path.make(path: "foo->bar"))

        // three names
        path = try Path.make(path: "x->y->z")
        #expect(path.count == 3)
        #expect(path[0] == "x")
        #expect(path[1] == "y")
        #expect(path[2] == "z")
        #expect(path.description == "x->y->z")
        #expect(try path == Path.make(path: "x->y->z"))
    }
}
