#!/usr/bin/env bash

export RUN_SCRIPT=${BASH_SOURCE[0]}

if [ -r $1 ]; then
  echo """
<!> DEPRECATION <!>
<!> You are using a deprecated call to this script.
<!> Please use the following options:
<!>   -i inventory : to set the inventory path to generate the ssh config file
<!>   -a           : to read the remote artifact
"""
  DEPRECATED_WAY="True"
  INVENTORY=$1
  REMOTE_ARTIFACT="True"
else
  while getopts ai: option
  do
    case "${option}"
    in
      a) REMOTE_ARTIFACT="True";; # Read the remote artifact
      i) INVENTORY=${OPTARG};;    # Set the inventory file for ssh config
    esac
  done
fi

export TOOLS_FOLDER=$(dirname $(readlink -f ${RUN_SCRIPT}))
export ROOT_FOLDER=${PWD}
. ${TOOLS_FOLDER}/rc.sh
trap submit_bug_report ERR

##############################################
step_banner "Tasked trigger infos"
##############################################
echo "POD: ${pod}"
echo "Pipeline triggered by: ${source_job_name}"

##############################################
step_banner "Prepare environment"
##############################################

# Set Vault password
VAULT_OPT=''
if [ -n "${ANSIBLE_VAULT_PASSWORD}" ]; then
  step_line "ansible vault password file"
  echo ${ANSIBLE_VAULT_PASSWORD} > ${ROOT_FOLDER}/.vault
  export VAULT_OPT="--vault-password-file ${ROOT_FOLDER}/.vault"
else
  step_line no vault password provided
fi

##############################################
step_banner "Get artifacts"
##############################################
if [ "${CI_PIPELINE_SOURCE}" == "trigger" ] && [ "${REMOTE_ARTIFACT}" == "True" ]; then
  if [ -n "${artifacts_src}" ] || [ -n "${artifacts_bin}" ]; then
    if [ -n "${artifacts_src}" ]; then
      step_line "getting artifact from source url"
      step_line "(your may need to set PRIVATE_TOKEN argument to access non public artifact)"
      curl -L -s -H "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" -o "${ROOT_FOLDER}/artifacts.zip" "${artifacts_src}"
    elif [ -n "${artifacts_bin}" ]; then
      step_line "getting artifact from its binary content"
      echo "${artifacts_bin}" | base64 -d > ${ROOT_FOLDER}/artifacts.zip
    fi
    step_line "unzip artifacts"
    unzip -o ${ROOT_FOLDER}/artifacts.zip -d ${ROOT_FOLDER}
    rm ${ROOT_FOLDER}/artifacts.zip
  else
    step_line "No artifact provided"
    exit -1
  fi
else
  step_line "Pipeline not triggered (\$CI_PIPELINE_SOURCE=${CI_PIPELINE_SOURCE})"
  step_line "or remote artifact option '-a' not set"
fi

##############################################
step_banner "Set SSH config"
##############################################
if [ -e ${ROOT_FOLDER}/vars/vaulted_ssh_credentials.yml ]; then
  if [ -z "${INVENTORY}" ]; then
    error_line "No Inventory provided (-i option)"
    exit -1
  else
    check_ci_var ANSIBLE_VAULT_PASSWORD
    check_ci_var INVENTORY
    step_line Generate SSH config
    ansible-playbook ${ansible_verbose} -i ${INVENTORY} ${VAULT_OPT} ${TOOLS_FOLDER}/prepare_ssh.yml
    export SSH_OPT="-F ${ROOT_FOLDER}/ssh_config"
    export ANSIBLE_SSH_ARGS="-C -o ControlMaster=auto -o ControlPersist=60s ${SSH_OPT}"
    if [ "${DEPRECATED_WAY}" == "True" ]; then
      step_line Add symlink to support DEPRECATED calls of this script
      ln -s ${ROOT_FOLDER}/ssh_config ${ROOT_FOLDER}/config
    fi
  fi
else
  step_line "no ssh creds"
fi

##############################################
step_banner "End of preparation"
##############################################
