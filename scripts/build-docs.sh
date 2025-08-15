#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 1
cd ..
yardoc --output-dir ./yard-docs ./mygame/lib
