#!/usr/bin/env bash

# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 Orange and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

##
# Bug report function
##
submit_bug_report() {
  SHELL_VERBOSE=${SHELL_VERBOSE:-}
  local lc="$BASH_COMMAND" rc=$?
  echo ""
  echo "---------------------------------------------------------------------"
  step_line "Crash on command"
  echo
  echo $lc
  echo
  step_line "Exit code"
  echo
  echo $rc
  if [ ! -z ${SHELL_VERBOSE} ]; then
    echo
    step_line "Environment variables"
    echo
    env | grep -v artifacts_bin \
        | sort \
        | sed 's/^/export /' \
        | sed 's/PASSWORD=.*/PASSWORD=***HIDDEN***/' \
        | sed 's/artifacts_bin=.*/artifacts_bin=***HIDDEN***/'
  fi
  echo "---------------------------------------------------------------------"
  step_banner "Clean"
  ${TOOLS_FOLDER}/clean.sh
  echo "---------------------------------------------------------------------"
}


##
# Pretty print
##
step_banner() {
  echo ""
  echo "====================================================================="
  echo "${RUN_SCRIPT}"
  date
  echo "$*"
  echo "====================================================================="
  echo ""
}

step_line() {
  echo ">>> ${*}"
}

error_line() {
  echo "!!! ${*}"
}

##
# Test A CI var is required
##
check_ci_var() {
  var_name=$1
  if [ -z "${!var_name}" ]; then
    error_line
    error_line "Variable \$${var_name} must be defined"
    error_line "Please set it in your gitlab project (Settings / CI-CD / variables page)"
    error_line
    exit
  fi
}

##
# Warn if run as root
##
no_root_needed() {
  step_line "Check if we are root"
  if [[ $(whoami) == "root" ]]; then
      echo "WARNING: This script should not be run as root!"
      echo "Elevated privileges are aquired automatically when necessary"
      echo "Waiting 10s to give you a chance to stop the script (Ctrl-C)"
      for x in $(seq 10 -1 1); do echo -n "$x..."; sleep 1; done
  fi
}

##
# Ensure root folder is not world readable
##
ansible_prepare(){
  step_line "Set local folder not writable to others"
  chmod 600 ${ROOT_FOLDER}
}

##
# SSH Options
##
ssh_opt(){
  SSH_OPT=''
  if [ -e ${ROOT_FOLDER}/vars/vaulted_ssh_credentials.yml ]; then
    SSH_OPT="${SSH_OPT} -F ${ROOT_FOLDER}/ssh_config"
  fi
  echo ${SSH_OPT}
}

##
# Vault Options
##
vault_opt(){
  VAULT_OPT=''
  if [ -n "${ANSIBLE_VAULT_PASSWORD}" ]; then
    VAULT_OPT="--vault-password-file ${ROOT_FOLDER}/.vault"
  fi
  echo ${VAULT_OPT}
}

##
# Get Ansible SSH Options
##
ansible_ssh_opt(){
  ANSIBLE_SSH_ARGS="-C -o ControlMaster=auto -o ControlPersist=60s"
  if [ -n "${ANSIBLE_VAULT_PASSWORD}" ]; then
    ANSIBLE_SSH_ARGS="${ANSIBLE_SSH_ARGS} $(ssh_opt)"
  fi
  echo ${ANSIBLE_SSH_ARGS}
}

##
# Cat file that may be vaulted
##
cat_file(){
  FILE=$1
  if [ -e ${ROOT_FOLDER}/.vault ] \
     && $(grep '^\$ANSIBLE_VAULT;1\..;AES256' ${FILE} > /dev/null); then
    ansible-vault view --vault-password-file=${ROOT_FOLDER}/.vault ${FILE}
  else
    cat ${FILE}
  fi
}
