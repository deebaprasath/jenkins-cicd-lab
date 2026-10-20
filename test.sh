#!/bin/sh
set -eu

echo "Running website tests..."

test -f index.html
test -f Dockerfile

grep -q "The commands you keep forgetting" index.html
grep -q "Linux" index.html
grep -q "Git" index.html
grep -q "Docker" index.html
grep -q "FROM nginx:alpine" Dockerfile

echo "All website tests passed!"
