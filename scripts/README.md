# chained-ci-tools

Library to unify the usage of chained-ci

How to run
----

To prepare the environment just run:
```./<chained-ci-tools_folder>/chained-ci-init.sh [-a] [-i inventory]```

This will prepare depending on your artifacts and env vars:

- The vault key file
- Get the artifacts that came from chained-ci
- Set the ssh key and the ssh config

Options are:
- ```-a```: Read the remote artifact
- ```-i inventory```: Set the inventory file for ssh config

For security purpose, the environment should ALWAYS be clean! the proposed
script underneath will:
- Remove the vault key file
- Remove the ssh config file with id_rsa key files
- Vault ALL the artifact files of the current job. To add an exception, and do
  not vault a file, or a folder, you can set the NOVAULT_LIST parameter filled
  with paths separated by a carriage return or a space, like this:
  ```
  NOVAULT_LIST="""folder1/file2
  folder2/file2
  folder3/"""
  ```
  or
  ```
  NOVAULT_LIST="folder1/file2 folder2/file2 folder3/"
  ```
  Please note the '/' at the end of the folder; it will work without but you may
  also filter all names starting with "folder3"


to use the clean script of the environment, just run:
```
./<chained-ci-tools_folder>/clean.sh
```


Use it as a submodule
----------

```
git submodule add https://gitlab.com/Orange-OpenSource/lfn/ci_cd/chained-ci-tools.git scripts/chained-ci-tools
```

If you use the CI, don't forget to add the following parameter in ```.gitlab-ci.yml```
```
variables:
  GIT_SUBMODULE_STRATEGY: recursive
```


Chained-ci-tools in gitlab-ci.yml
--------

In your ```.gitlab-ci.yml```, you can add:
```
.chained_ci_tools: &chained_ci_tools
  before_script:
    - ./scripts/chained-ci-tools/chained-ci-init.sh -a -i inventory
  after_script:
    - ./scripts/chained-ci-tools/clean.sh
```

and add this block when you need to run it
```
<<: *chained_ci_tools
```
