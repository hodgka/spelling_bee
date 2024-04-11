#! /bin/bash
mkdir -p build/
odin build src/ -out:build/spelling_bee && \
    ./build/spelling_bee