Vagrant.require_version ">= 2.2.0"
VAGRANTFILE_API_VERSION = "2"

require './modules/dockerbox'

DockerBox::ensure_windows_hyperv_is_disable_when_up_or_reload()
DockerBox::install_specified_plugins( %w( vagrant-vbguest ) )
configuration = DockerBox::read_configuration( 'config.yaml' )
DockerBox::install_extra_plugins_from_configuration( configuration )
DockerBox::setup_vagrant_provider_from_configuration( configuration )
single_machine = DockerBox::get_single_machine_properties( configuration )
provision = DockerBox::get_provision_properties( configuration )
multi_machine = DockerBox::get_multi_machine_properties( configuration )

Vagrant.configure( "2" ) do | config |
  multi_machines_vm_prefix_builder = DockerBox::MultiMachineVmPrefixBuilder.new( 'config.yaml' )

  multi_machines_hostname_prefix_map = {}

  # creating machines
  multi_machine.ip_addresses.each_with_index do | ip, multi_machine_index |
    config.ssh.username = "docker"

    if single_machine.ssh_command_extra_args.length > 0
      config.ssh.extra_args = single_machine.ssh_command_extra_args
    end

    machine_name = multi_machines_vm_prefix_builder.get_next_vm_prefix( multi_machine_index )

    config.vm.define "#{ machine_name }" do | machine |
      machine.vm.box = "metabarj0/DockerBox"
      machine.vm.box_version = ">= 3.0.0"

      if DockerBox::is_multi_machine_enabled( multi_machine )
        hostname_prefix = multi_machine_hostname_prefixes[ multi_machine_index ]

        if ( hostname_prefix == nil ) || hostname_prefix.empty?
          hostname_prefix = hostname
        end

        if multi_machines_hostname_prefix_map.include?( hostname_prefix )
          multi_machines_hostname_prefix_map[ hostname_prefix ] = multi_machines_hostname_prefix_map[ hostname_prefix ] + 1
        else
          multi_machines_hostname_prefix_map[ hostname_prefix ] = 0
        end

        machine.vm.hostname = "#{ hostname_prefix }-#{ multi_machines_hostname_prefix_map[ hostname_prefix ] }"
      else
        machine.vm.hostname = single_machine.hostname
      end

      # vagrant bug : not supported but should work as soon as vagrant has fixed its stuff
      is_unique_machine_public_network_enabled = single_machine.create_public_network && ( not is_multi_machine_enabled )
      is_multi_machine_public_network_enabled = multi_machine.create_public_network[ multi_machine_index ]

      if is_unique_machine_public_network_enabled || is_multi_machine_public_network_enabled
        machine.vm.network "public_network"
      end

      # forwarding only applies on the first machine
      if( multi_machine_index == 0 )
        if single_machine.forwarded_ports
          single_machine.forwarded_ports.each { | rule |
            machine.vm.network "forwarded_port", guest: rule[ 'guest' ], host: rule[ 'host' ], protocol: rule[ 'protocol' ]
          }
        end
      end

      if single_machine.synced_folders
        has_multi_machine_synced_folders = multi_machine_shared_synced_folders[ multi_machine_index ]

        if ( not is_multi_machine_enabled ) || has_multi_machine_synced_folders
          synced_folders.each { | machine_synced_folder |
            machine.vm.synced_folder machine_synced_folder[ 'host' ], machine_synced_folder[ 'guest' ]
          }
        end
      end

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
