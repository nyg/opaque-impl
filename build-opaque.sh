#!/usr/bin/env sh

cd opaque

sage --preparse *.sage

for f in *.sage.py
do
    mv "$f" ${f%%.*}.py
done
