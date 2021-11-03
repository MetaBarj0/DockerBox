Vagrant.require_version ">= 2.2.0"
VAGRANTFILE_API_VERSION = "2"

require './modules/dockerbox'

project = DockerBox::VagrantProject.new( 'config.yaml' )










Vagrant.configure( "2" ) do | config |
  multi_machines_vm_prefix_builder = DockerBox::MultiMachineVmPrefixBuilder.new( 'config.yaml' )
  multi_machines_hostname_builder = DockerBox::MultiMachineHostnameBuilder.new( 'config.yaml' )

  # creating machines
  DockerBox::get_machines_ip_addresses( 'config.yaml' ).each_with_index do | ip, multi_machine_index |
    config.ssh.username = "docker"
    config.ssh.extra_args = DockerBox::get_machine_ssh_command_extra_args( 'config.yaml' )

    config.vm.define "#{ multi_machines_vm_prefix_builder.get_next_vm_prefix( multi_machine_index ) }" do | machine |
      machine.vm.box = "metabarj0/DockerBox"
      machine.vm.box_version = ">= 3.0.0"
      machine.vm.hostname = multi_machines_hostname_builder.get_next_hostname( multi_machine_index )

      if DockerBox::has_public_network( 'config.yaml', multi_machine_index )
        machine.vm.network "public_network"
      end

      DockerBox::get_forwarded_ports( 'config.yaml', multi_machine_index ).each { | rule |
        machine.vm.network "forwarded_port", guest: rule[ 'guest' ], host: rule[ 'host' ], protocol: rule[ 'protocol' ]
      }

      DockerBox::get_synced_folders( 'config.yaml', multi_machine_index ).each { | synced_folder |
        machine.vm.synced_folder synced_folder[ 'host' ], synced_folder[ 'guest' ]
      }

      if DockerBox::is_multi_machine_enabled( 'config.yaml' )
        machine.vm.network "private_network", ip: "#{ ip }"
      end

      # virtualbox provider specific configuration with defaults
      machine.vm.provider "virtualbox" do | v |
        v.customize [ "modifyvm", :id, "--cpus", DockerBox::get_machine_cpu_count( 'config.yaml', multi_machine_index ) ]
        v.customize [ "modifyvm", :id, "--cpuexecutioncap", DockerBox::get_machine_cpu_cap( 'config.yaml', multi_machine_index ) ]
        v.customize [ "modifyvm", :id, "--memory", DockerBox::get_machine_memory( 'config.yaml', multi_machine_index ) ]
      end

      # shell provisioning
      machine.vm.provision "shell", path: "provisioning/provision-from-host.sh",
                                    env:
                                    {
                                      "MACHINE_HOSTNAME"          => machine.vm.hostname,
                                      "ZONEINFO_REGION"           => DockerBox::get_provision_properties( 'config.yaml' ).zoneinfo_region,
                                      "ZONEINFO_CITY"             => DockerBox::get_provision_properties( 'config.yaml' ).zoneinfo_city,
                                      "KEYMAP"                    => DockerBox::get_provision_properties( 'config.yaml' ).keymap,
                                      "KEYMAP_VARIANT"            => DockerBox::get_provision_properties( 'config.yaml' ).keymap_variant,
                                      "EXTRA_PACKAGES"            => DockerBox::get_provision_properties( 'config.yaml' ).extra_packages,
                                      "DOCKER_VOLUME_AUTO_EXTEND" => DockerBox::get_provision_properties( 'config.yaml' ).docker_volume_auto_extend,
                                      "KV_DB_FILE"                => DockerBox::get_provision_properties( 'config.yaml' ).kv_db_file,
                                      "KV_DB_FILE_CREATE_LINK"    => DockerBox::get_provision_properties( 'config.yaml' ).kv_db_file_create_link,
                                      "KV_RECORD_SEPARATOR"       => DockerBox::get_provision_properties( 'config.yaml' ).kv_record_separator,
                                      "KV_ASSIGNMENT_OPERATOR"    => DockerBox::get_provision_properties( 'config.yaml' ).kv_assignment_operator,
                                      "KV_DB_RECORDS"             => DockerBox::get_provision_properties( 'config.yaml' ).kv_db_records
                                    }

    end
  end
end
