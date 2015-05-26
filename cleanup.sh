#!/bin/bash

IFS=$'\n'

for folder in $(find -mindepth 1 -maxdepth 1 -type d | grep -v '\.git' )
do
    rm -rf "$folder"
done
