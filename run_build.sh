#!/bin/bash

docker run --rm -v `pwd`:/local ghcr.io/casadi/web:latest ./build.sh
