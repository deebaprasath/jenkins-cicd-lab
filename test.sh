#!/bin/sh
set -eu

echo "Running website tests..."

# Required source files
test -f index.html
test -f Dockerfile

# Validate the current website
grep -qi "DevOps pipeline simulator" index.html
grep -qi "GitHub" index.html
grep -qi "Jenkins" index.html
grep -qi "Docker" index.html
grep -qi "EC2" index.html

# Validate the Docker configuration
grep -q "FROM nginx:alpine" Dockerfile
grep -q "COPY index.html" Dockerfile

echo "All website tests passed!"
