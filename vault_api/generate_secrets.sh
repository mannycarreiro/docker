#!/bin/bash
set -e

/usr/bin/clear

validatevars(){
    local env_variable="${1}"
    if [ -z "${!env_variable+x}" ]; then
        echo "Variable ${env_variable} is NOT DEFINED"
	RC=1
    else
       echo "Variable ${env_variable} is defined"
    fi
}
help(){

	echo ""
	echo "=============================================================="
	echo "The following environment Variables needs to be defined:"
	echo "${variables}"
	echo ""
	echo "=============================================================="
	echo ""
	exit 1

}

variables="VAULT_ADDR,VAULT_ROLE_ID,VAULT_SECRET_ID,VAULT_APPNAME,VAULT_ENV_FILES_DIR"
IFS=","
for v in ${variables}; do
    validatevars "${v}"
done

if [[ "${RC}" -eq 1 ]]; then
   help
fi

cd $(dirname "$0")

docker build -t vaultapi . && docker run --rm -it -v ${VAULT_ENV_FILES_DIR}:/opt/secret_fetch/env_files_dir \
       	-e VAULT_ADDR="${VAULT_ADDR}" \
        -e VAULT_ROLE_ID="${VAULT_ROLE_ID}" \
        -e VAULT_SECRET_ID="${VAULT_SECRET_ID}" \
        -e APPNAME="${VAULT_APPNAME}" \
	vaultapi
