#!/bin/bash

sudo mkdir -p public
docker run --rm -v `pwd`:/local ghcr.io/casadi/web:latest ./build.sh
sudo chmod a+w -R public
cp -R content/api public
touch public/.nojekyll # To make sure files with leading _underscore are served on github pages
echo "web.casadi.org" > CNAME
cp CNAME public
