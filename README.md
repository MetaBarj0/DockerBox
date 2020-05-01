# DockerBox

Alpine Linux based image with docker. Customizable provisioning.
<https://app.vagrantup.com/metabarj0/boxes/DockerBox/versions/2.0.1> is the currently supported version.

## configuration

You can customize the VM by creating a .env file from the provided .env.dist
template. Each variable's purpose is described as a comment.

## login

There is 3 accounts :

- root    => vagrant  
- vagrant => vagrant  
- docker  => docker

## storage

This virtual machine is designed to be a docker host. Should your
containerization projects grow in space, you can easily extend the storage
allocated for docker without having to type a single command.
First, add and/or extend a virtual disk file to your VM. You can do that
using the virtualbox GUI.
You can use any storage controller you want.
Then, ensure the environment variable `DOCKER_VOLUME_AUTO_EXTEND` is set to
`1` in your `.env` file. Finally, run `vagrant provision` to auto extend the
storage for docker according to virtual disk files you added or resized.
