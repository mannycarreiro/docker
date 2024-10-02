#!/bin/sh

docker run --rm -it -v ${1}:/opt/secret_fetch/env_files --env-file "${2}"
