# ONAP automatic installation via OOM

This project aims to automatically install ONAP. Its config source
is shared config files among all OPNFV installers:
- PDF - Pod Description File: describing the hardware level of the
  infrastructure hosting the VIM
- IDF - Installer Description File: A flexible file allowing installer to
  set specific parameters close to the infra settings, linked with the install
  sequence
- DDF - Datacenter Description File: A flexible file allowing installer to set
  specific information about the datacenter where OOM is deployed

## Goal

The goal of this installer is to install in a repeatable and reliable way ONAP
using OOM installer.


## Input

  - configuration files:
    - mandatory:
        - vars/pdf.yml: POD Description File
        - vars/idf.yml: POD Infrastructure description File
        - vars/ddf.yml: Datacenter Description File
        - vars/user_cloud.yml: Credential to connect to an OpenStack (in order
          to create a first cloud inside ONAP)
        - inventory/infra: the ansible inventory for the servers
    - optional:
        - vars/vaulted_ssh_credentials.yml: Ciphered private/public pair of key
          that allows to connect to jumphost and servers
        - vars/components-overrides.yml: if you want to deploy a specific
          set of components, set it here.
  - Environment variables:
    - mandatory:
        - PRIVATE_TOKEN: to get the artifact
        - artifacts_src: the url to get the artifacts
        - OR artifacts_bin: b64_encoded zipped artifacts (tbd)
        - ANSIBLE_VAULT_PASSWORD: the vault password needed by ciphered ansible
          vars
    - optional:
      - RUNNER_TAG:
        - override the default gitlab-runner tag
      - CLEAN:
          - role: Do we clean previus ONAP installation
          - values type: Boolean
          - default: False
      - ANSIBLE_VERBOSE:
          - role: verbose option for ansible
          - values: "", "-vvv"
          - default: ""
      -  GERRIT_REVIEW:
         -  role: gerrit review to use
         -  value type: string
         -  default: ""
      -  GERRIT_PATCHSET:
         -  role: gerrit patchset to use in the gerrit review
         -  value type: string
         -  default: ""
      - HELM_VERSION:
          - role: the helm version that should be present
          - default: "v3.8.2"
      - USE_JUMPHOST:
          - role: do we need to connect via a jumphost or not?
          - value type: boolean
          - default: "yes"
      - PROXY_COMMAND:
          - role: do we need to use a proxy command to reach the jumphost or
            not?
          - value: "", "the proxy command (example: connect -S socks:1080 %h
            %p)"
          - default: ""
      - VNFS_TENANT_NAME:
          - role: the name of the first tenant for VNF
          - value type: string
          - default: the value in idf (os_infra.tenant.name).
      - VNFS_USER_NAME:
          - role: the name of the first tenant user for VNF
          - value type: string
          - default: the value in idf (os_infra.user.name).
      - ONAP_REPOSITORY:
          - role: choose the repository where to download ONAP
          - value type: string
          - default: nexus.onap.eu
      - ONAP_NAMESPACE:
          - role: the namespace deployment in kubernetes
          - value type: string
          - default: "onap"
      - ONAP_CHART_NAME:
          - role: the name of the deployment in helm
          - value type: string
          - default: the value of ONAP_NAMESPACE
      - OOM_BRANCH
          - role: branch/tag of OOM to deploy
          - value type: string
          - default: "master"
      - ONAP_FLAVOR:
          - role: the size of ONAP Pods limits
          - values: "small", "large", "unlimited"
          - default: "unlimited"
      - POD:
          - role: name of the pod when we'll insert healtcheck results
          - value type;: string
          - default: empty
      - DEPLOYMENT:
          - role: name of the deployment for right tagging when we'll insert
            healtcheck results
          - value type: string
          - default: "rancher"
      - DEPLOYMENT_TYPE:
          - role: type of ONAP deployment expected
          - values: "core", "small", "medium", "full"
          - default: "full"
      - ADDITIONAL_COMPONENTS:
          - role: additional components to install on top of a deployment type
          - value type: comma-separated list (example: "clamp,policy")
      - TEST_RESULT_DB_URL:
          - role: url of test db api
          - value type: string
          - default: "http://testresults.opnfv.org/test/api/v1/results"
      - INGRESS:
          - role: do we want to use ingress with ONAP or not
          - value type: boolean
          - default: False
      - GATHER_NODE_FACTS:
          - role: do we need to gather facts from node on postinstallation
          - value type: boolean
          - default: true
      - HELM3_USE_SQL
          - role: ask to use SQL backend for helm3
          - value type: bool
          - default: False


## Output
  - artifacts:
    - vars/cluster.yml

## Deployment types

- core: aaf, aai, dmaap, robot, sdc, sdnc, so
- small: core + appc, cli, esr, log, msb, multicloud, nbi, portal, vid
- medium: small + clamp, contrib, dcaegen2, oof, policy, pomba
- full: all onap components

## Additional components:

List of components available:

- medium components + modeling, vnfsdk, vfc, uui, sniro_emulator
