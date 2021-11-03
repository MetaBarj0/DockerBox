Vagrant.require_version ">= 2.2.0"
VAGRANTFILE_API_VERSION = "2"

require './modules/dockerbox'

DockerBox::ensure_windows_hyperv_is_disable_when_up_or_reload()
DockerBox::install_specified_plugins( %w( vagrant-vbguest ) )
configuration = DockerBox::read_configuration( 'config.yaml' )
DockerBox::install_extra_plugins_from_configuration( configuration )
DockerBox::setup_vagrant_provider_from_configuration( configuration )

Vagrant.configure( "2" ) do | config |
  single_machine = DockerBox::get_single_machine_properties( configuration )
  multi_machine = DockerBox::get_multi_machine_properties( configuration )
  provision = DockerBox::get_provision_properties( configuration )

  multi_machines_vm_prefix_builder = DockerBox::MultiMachineVmPrefixBuilder.new( 'config.yaml' )
  multi_machines_hostname_builder = DockerBox::MultiMachineHostnameBuilder.new( 'config.yaml' )

  # creating machines
  multi_machine.ip_addresses.each_with_index do | ip, multi_machine_index |
    config.ssh.username = "docker"
    config.ssh.extra_args = single_machine.ssh_command_extra_args

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

      if DockerBox::is_multi_machine_enabled( multi_machine )
        machine.vm.network "private_network", ip: "#{ ip }"
      end

      current_machine_cpu = single_machine.cpu

      if DockerBox::is_multi_machine_enabled( multi_machine )
        if ( not multi_machine_cpus[ multi_machine_index ] == nil ) && ( multi_machine_cpus[ multi_machine_index ] > 0 )
          current_machine_cpu = multi_machine_cpus[ multi_machine_index ]
        end
      end

      current_machine_cpu_cap = single_machine.cpu_cap

      if DockerBox::is_multi_machine_enabled( multi_machine )
        if ( not multi_machine_cpu_caps[ multi_machine_index ] == nil ) && ( multi_machine_cpu_caps[ multi_machine_index ] > 0 )
          current_machine_cpu_cap = multi_machine_cpu_caps[ multi_machine_index ]
        end
      end

      current_machine_memory = single_machine.memory

      if DockerBox::is_multi_machine_enabled( multi_machine )
        if ( not multi_machine_memories[ multi_machine_index ] == nil ) && ( multi_machine_memories[ multi_machine_index ] > 0 )
          current_machine_memory = multi_machine_memories[ multi_machine_index ]
        end
      end

      # virtualbox provider specific configuration with defaults
      machine.vm.provider "virtualbox" do | v |
        v.customize [ "modifyvm", :id, "--cpus", current_machine_cpu ]
        v.customize [ "modifyvm", :id, "--cpuexecutioncap", current_machine_cpu_cap ]
        v.customize [ "modifyvm", :id, "--memory", current_machine_memory ]
      end

      # shell provisioning
      machine.vm.provision "shell", path: "provisioning/provision-from-host.sh",
                                    env:
                                    {
                                      "MACHINE_HOSTNAME"          => machine.vm.hostname,
                                      "ZONEINFO_REGION"           => provision.zoneinfo_region,
                                      "ZONEINFO_CITY"             => provision.zoneinfo_city,
                                      "KEYMAP"                    => provision.keymap,
                                      "KEYMAP_VARIANT"            => provision.keymap_variant,
                                      "EXTRA_PACKAGES"            => provision.extra_packages,
                                      "DOCKER_VOLUME_AUTO_EXTEND" => provision.docker_volume_auto_extend,
                                      "KV_DB_FILE"                => provision.kv_db_file,
                                      "KV_DB_FILE_CREATE_LINK"    => provision.kv_db_file_create_link,
                                      "KV_RECORD_SEPARATOR"       => provision.kv_record_separator,
                                      "KV_ASSIGNMENT_OPERATOR"    => provision.kv_assignment_operator,
                                      "KV_DB_RECORDS"             => provision.kv_db_records
                                    }

    end
  end
end
