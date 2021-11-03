# DockerBox

An alternative to Docker Desktop working with Vagrant and Virtualbox.

As its core, it relies on a minimal installation of Alpine Linux.

It supports customisable provisioning through a comprehensible configuration in
a yaml file.

<https://app.vagrantup.com/metabarj0/boxes/DockerBox/versions/3.0.1> is the
latest supported version.

## getting started

- Clone this repository
- Create a `config.yaml` file using the `config.yaml.dist` file provided in the
  repository
- Issue the `vagrant up` command
- Enter in one of the created virtual machines using
  `vagrant ssh [name|id] [-- extra_ssh_args]` command

## Configuration

You can customize the created virtual machines by creating a `config.yaml` file
from the provided `config.yaml.dist` template. Each variable's purpose is
described as a comment.

## login

There are 3 accounts :

| login   | password |
| ------- | -------- |
| root    | vagrant  |
| vagrant | vagrant  |
| docker  | docker   |

When you enter with ssh in one of created virtual machine by issuing the
`vagrant ssh [name|id] [-- extra_ssh_args]`, you'll be logged as `docker` and
you'll be able to use all the docker tooling.

## storage

Virtual machines are designed to be a docker host. Should your containerization
projects grow in space, you can easily extend the storage allocated for docker
without having to type a single command.  First, add and/or extend a virtual
disk file to your VM. You can do that using the hypervisor GUI.  You can use any
storage controller you want.  Then, ensure the environment variable
`provisioning.docker_volume_auto_extend` is set to `true` in your `config.yaml`
file. Finally, run `vagrant provision` or `vagrant up --provision` or
`vagrant reload --provision` to auto extend the storage for docker according to
virtual disk files you added or resized.

## multi machine

Multi machines configuration is fully supported (see
<https://www.vagrantup.com/docs/multi-machine/)>).
See in the `config.yaml.dist` file configuration sections related to
`multi_machine` configuration for more information.
