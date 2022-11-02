#!/usr/bin/env sh

export TOOLS_FOLDER=$(dirname $(readlink -f ${0}))
export ROOT_FOLDER=${PWD}
. ${TOOLS_FOLDER}/rc.sh

###############################################################
step_banner Artifact ciphering
###############################################################

# Function to check a file is in a list
file_in_list (){
  LIST=$(echo $1|tr '\\n' ' ') #if we send it with CR separator
  FILE=$2
  for FILTER in ${LIST}; do
    if $(echo ${FILE}| grep "^${FILTER}" 2>&1 >/dev/null); then
      return 0
    fi
  done
  return 1
}

if [ -e ${ROOT_FOLDER}/.vault ]; then
  #Ensure we have a NOVAULT_LIST
  NOVAULT_LIST="fake/file ${NOVAULT_LIST}"
  #Get artifacts paths
  INV_PATHS=$(cat .gitlab-ci.yml | yq --arg job ${CI_JOB_NAME} -r '.[$job].artifacts.paths[]')
  #Read paths
  for INV_PATH in ${INV_PATHS}; do
    if [ -e ${INV_PATH} ]; then
      #If the artifact is a directory, reads files in it
      if [ -d ${INV_PATH} ]; then
        FILES=$(find ${INV_PATH} -type f)
      else
        FILES=${INV_PATH}
      fi
      # For each file, vault or not
      for FILE in ${FILES}; do
        if $(file_in_list "${NOVAULT_LIST}" ${FILE}); then
          echo "${FILE}: Not vaulting"
        else
          if $(head -n1 ${FILE} |grep "^\$ANSIBLE_VAULT;" > /dev/null); then
            echo "${FILE}: Already vaulted"
          else
            echo "${FILE}: Vaulting"
            ansible-vault encrypt --vault-password-file ${ROOT_FOLDER}/.vault ${FILE}
          fi
        fi
      done
    fi
  done
fi

###############################################################
step_banner Cleaning all files
###############################################################
if [ -e ${ROOT_FOLDER}/.vault ]; then
  step_line remove vault file
  rm ${ROOT_FOLDER}/.vault
fi
if [ -e ${ROOT_FOLDER}/id_rsa ]; then
  step_line remove ssh certs
  rm  ${ROOT_FOLDER}/id_rsa
fi
if [ -e ${ROOT_FOLDER}/id_rsa.pub ]; then
  step_line remove pub ssh certs
  rm  ${ROOT_FOLDER}/id_rsa.pub
fi
if [ -e ${ROOT_FOLDER}/ssh_config ]; then
  step_line remove ssh config
  rm  ${ROOT_FOLDER}/ssh_config
fi
if [ -e ${ROOT_FOLDER}/vars/openstack_openrc ]; then
  step_line remove openstack admin rc
  rm  ${ROOT_FOLDER}/vars/openstack_openrc
fi
