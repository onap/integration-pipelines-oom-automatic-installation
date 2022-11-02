#!/bin/bash

# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 Orange and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o nounset
set -o pipefail

labels=$*

RUN_SCRIPT=${0}
RUN_ROOT=$(dirname $(readlink -f ${RUN_SCRIPT}))
export RUN_ROOT=$RUN_ROOT
source ${RUN_ROOT}/scripts/rc.sh

# register our handler
trap submit_bug_report ERR

#-------------------------------------------------------------------------------
# If no labels are set with args, run all
#-------------------------------------------------------------------------------
if [[ $labels = "" ]]; then
  labels="ci prepare configure deploy wait postconfigure check_containers healtcheck"
fi

step_banner "Fetch galaxy roles"
ansible-galaxy install -r requirements.yml

if [[ $labels = *"clean"* ]]; then
  #-------------------------------------------------------------------------------
  # Prepare CI
  #  - install needed packages and verify directory are writable
  #-------------------------------------------------------------------------------
  step_banner "Prepare CI"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i ${RUN_ROOT}/inventory/infra \
    ${RUN_ROOT}/onap-oom-prepare-ci.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "CI prepared"

  #-------------------------------------------------------------------------------
  # Prepare OOM
  #  - create helm servers
  #  - compile OOM helm packages and push them to local server
  #-------------------------------------------------------------------------------
  step_banner "Clean OOM"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i ${RUN_ROOT}/inventory/infra \
    ${RUN_ROOT}/onap-oom-clean.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "OOM cleaned"
fi

if [[ $labels = *"prepare"* ]]; then
  #-------------------------------------------------------------------------------
  # Prepare CI
  #  - install needed packages and verify directory are writable
  #-------------------------------------------------------------------------------
  step_banner "Prepare CI"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i ${RUN_ROOT}/inventory/infra \
    ${RUN_ROOT}/onap-oom-prepare-ci.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "CI prepared"

  #-------------------------------------------------------------------------------
  # Prepare OOM
  #  - create helm servers
  #  - compile OOM helm packages and push them to local server
  #-------------------------------------------------------------------------------
  step_banner "Prepare OOM"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i ${RUN_ROOT}/inventory/infra \
    ${RUN_ROOT}/onap-oom-prepare.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "OOM prepared"
fi

#-------------------------------------------------------------------------------
# Configure OOM
#  - retrieve tenant information
#  - encrypt tenant password
#  - generate OOM configuration
#-------------------------------------------------------------------------------
if [[ $labels = *"configure"* ]]; then
  step_banner "Configure OOM ${DEPLOYMENT_TYPE}"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i inventory/infra \
    ${RUN_ROOT}/onap-oom-configure.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "OOM ${DEPLOYMENT_TYPE} configured"
fi

#-------------------------------------------------------------------------------
# Deploy OOM
#  -  launch installation via HELM
#-------------------------------------------------------------------------------
if [[ $labels = *"deploy"* ]]; then
  step_banner "Deploy OOM"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i inventory/infra \
    ${RUN_ROOT}/onap-oom-deploy.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "OOM deployed"
fi

#-------------------------------------------------------------------------------
# Wait for End of Deployment
#  -  Wait that all pods are started
#-------------------------------------------------------------------------------
if [[ $labels = *"wait"* ]]; then
  step_banner "Wait for end of deployment"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i inventory/infra \
    ${RUN_ROOT}/onap-oom-wait.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "End of deployment done"
fi

#-------------------------------------------------------------------------------
# Postconfigure OOM
#  -  Create VIM in multicloud
#-------------------------------------------------------------------------------
if [[ $labels = *"postconfiguration"* ]]; then
  step_banner "Post configure OOM"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i inventory/infra \
    ${RUN_ROOT}/onap-oom-postconfigure.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "OOM postconfigured"
fi

#-------------------------------------------------------------------------------
# Postinstallation OOM
#  -  Generate /etc/hosts
#-------------------------------------------------------------------------------
if [[ $labels = *"postinstallation"* ]]; then
  step_banner "Post install OOM"
  ansible-playbook ${ANSIBLE_VERBOSE} \
    -i inventory/infra \
    ${RUN_ROOT}/onap-oom-postinstall.yaml --vault-id ${RUN_ROOT}/.vault

  step_banner "OOM postinstalled"
fi
