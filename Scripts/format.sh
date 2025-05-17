#!/bin/bash

docker pull ghcr.io/nicklockwood/swiftformat:latest
docker run --rm -v ./:/repo ghcr.io/nicklockwood/swiftformat:latest /repo
