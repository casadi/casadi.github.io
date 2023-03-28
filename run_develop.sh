#!/bin/bash

docker run --rm -v `pwd`:/local -p 127.0.0.1:1313:1313 ghcr.io/casadi/web:latest ./develop.sh
