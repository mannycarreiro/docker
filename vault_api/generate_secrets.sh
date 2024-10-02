#!/bin/sh

cd $(dirname "$0")
echo ${1}
echo ${2}
docker build -t vaultapi . && docker run --rm -it -v ${1}:/opt/secret_fetch/env_files_dir --env-file ${2} vaultapi

