#!/bin/bash

cd env_files_dir
CURRENT_DIR=$(pwd)
echo "Current Directory is ${CURRENT_DIR}"

vault_show_help(){
    echo ""
    echo "============================================="
    echo "====>> REQUIRED ENVIRONMENT VARIABLES <<====="
    echo "============================================="
    echo "VAULT_ADDR: Vault server address. Example: https://vault.example.com"
    echo "VAULT_ROLE_ID: Vault approle role id. Example: 123456-1234-1234-1234-1234567890"
    echo "VAULT_SECRET_ID: Vault approle secret id. Example: 123456-1234-1234-1234-123456"
    echo "APPNAME: Application name. Example: myappmount (If the secret path is docker/myappmount/secretname)"
    echo ""
}

check_env_vars(){
    ENV_VAR=${1}
    ENV_VAR_VALUE=$(printenv ${ENV_VAR})
    if [ -z "${ENV_VAR_VALUE}" ]; then
        echo "Error: ${ENV_VAR} environment variable is not set"
        vault_show_help
        exit 1
    else
        echo "Success: ${ENV_VAR} environment variable is set"
        echo "Value: ${ENV_VAR_VALUE}"
    fi
    
}


vault_validate(){
    check_env_vars VAULT_ADDR
    check_env_vars VAULT_ROLE_ID
    check_env_vars VAULT_SECRET_ID
    check_env_vars APPNAME
}

vault_get_credential(){
    echo "Getting ${SECRETNAME} from vault"
    SECRET_VALUE=$(curl -s -H "X-Vault-Token:${VAULT_TOKEN}" -request GET ${VAULT_ADDR}/v1/docker/data/${APPNAME} | jq -r --arg SECRETNAME ${SECRETNAME} ".data.data.$SECRETNAME")
    if [ "${SECRET_VALUE}" == "null" ]; then
        echo "SECRET ${SECRETNAME} not found in vault . . . Skipping"
    else
        echo "Success: Secret fetched from vault"
    fi
}


vault_generate_token(){
    echo "Generating vault token using approle"
    export VAULT_TOKEN=$(curl -s -X POST -d "{\"role_id\":\"${VAULT_ROLE_ID}\",\"secret_id\":\"${VAULT_SECRET_ID}\"}" ${VAULT_ADDR}/v1/auth/approle/login | jq -r '.auth.client_token')
    if [ -z "${VAULT_TOKEN}" ]; then
        echo "Error: Unable to generate vault token"
        exit 1
    else
        echo "Success: Vault token generated"
    fi
}

get_env_filenames(){
  NUM_FILES=$(find $PWD -type f -name "env" -o -name "*.env" | wc -l)
  if [ ${NUM_FILES} -eq 0 ]; then
      echo "No files to process"
      exit 0
  else
	  echo "Found ${NUM_FILES} file(s) to process"
	  FILELIST=$(find $PWD -type f -name "env" -o -name "*.env")
	  echo -e "File List is: ${FILELIST}"
  fi

}

generate_new_env_files(){
    get_env_filenames
    for file in ${FILELIST}; do
	echo -e "\n PROCESSING ${file}\n"
	cat ${file}
	echo -e "\n"
	ENV_FILENAME=$(basename ${file})
        echo "Fetching secrets from ${file}"
	ENV_TEMP_FILENAME=${ENV_FILENAME}.tmp
	cd $(dirname ${file})
	echo -n "" > ${ENV_TEMP_FILENAME}
        while IFS= read -r line; do
            SECRETNAME=$(echo ${line} | cut -d'=' -f1)
	    if [ ! -z "${SECRETNAME}" ]; then
            	echo "Secret Name: ${SECRETNAME}"
            	vault_get_credential ${SECRETNAME}
            	    if [ "${SECRET_VALUE}" != "null" ]; then
            	        echo "Updating ${SECRETNAME} in ${file}"
            		export ${SECRETNAME}="${SECRET_VALUE}"
            		echo "${SECRETNAME}=${SECRET_VALUE}" >> ${ENV_TEMP_FILENAME}
	    	    else
		        echo "${SECRETNAME} is not in vault.Copying same value to env file"
		        NONSECRETVALUE=$(echo "${line}" | cut -d'=' -f2)
		        echo "${SECRETNAME}=${NONSECRETVALUE}" >> ${ENV_TEMP_FILENAME}
                    fi
	         echo "Blank Line . . . Skipping"
             fi
        done < ${file}
	echo "Renaming ${file} to ${file}.original and ${file}.tmp to ${file}.env"
	mv ${file} ${file}.original && mv ${file}.tmp ${file}
    done
}
vault_validate
vault_generate_token
generate_new_env_files
