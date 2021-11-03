Vagrant.require_version '>= 2.2.0'

VAGRANTFILE_API_VERSION = '2'
BOX_NAME = 'metabarj0/DockerBox'
REQUIRED_BOX_VERSION = '>= 3.0.0'
CONFIG_FILE_NAME = 'config.yaml'

require './modules/dockerbox'

project = DockerBox::VagrantProject.new( CONFIG_FILE_NAME )

Vagrant.configure( VAGRANTFILE_API_VERSION ) do | config |
  project.from_machines_ip_addresses.each_with_index do | ip, machine_index |
    config.ssh.username = "docker"
    config.ssh.extra_args = project.get_machine_ssh_command_extra_args()

    config.vm.define "#{ project.get_next_machine_name_prefix( machine_index ) }" do | machine |
      machine.vm.box = BOX_NAME
      machine.vm.box_version = REQUIRED_BOX_VERSION
      machine.vm.hostname = project.get_next_machine_hostname( machine_index )

      if project.has_setup_public_network_for_machine( machine_index )
        machine.vm.network "public_network"
      end

      project.from_machine_forwarded_ports( machine_index ).each do | rule |
        machine.vm.network "forwarded_port", guest: rule[ 'guest' ], host: rule[ 'host' ], protocol: rule[ 'protocol' ]
      end 

      project.from_machine_synced_folders( machine_index ).each do | synced_folder |
        machine.vm.synced_folder synced_folder[ 'host' ], synced_folder[ 'guest' ]
      end 

      if project.is_multi_machine_enabled()
        machine.vm.network "private_network", ip: "#{ ip }"
      end

      machine.vm.provider "virtualbox" do | vm |
        vm.customize [ "modifyvm", :id, "--cpus", project.get_machine_cpu_count( machine_index ) ]
        vm.customize [ "modifyvm", :id, "--cpuexecutioncap", project.get_machine_cpu_cap( machine_index ) ]
        vm.customize [ "modifyvm", :id, "--memory", project.get_machine_memory( machine_index ) ]
      end

      machine.vm.provision "shell", path: "provisioning/provision-from-host.sh",
                                    env: {
                                      "MACHINE_HOSTNAME"          => machine.vm.hostname,
                                      "ZONEINFO_REGION"           => project.provisioning_properties().zoneinfo_region,
                                      "ZONEINFO_CITY"             => project.provisioning_properties().zoneinfo_city,
                                      "KEYMAP"                    => project.provisioning_properties().keymap,
                                      "KEYMAP_VARIANT"            => project.provisioning_properties().keymap_variant,
                                      "EXTRA_PACKAGES"            => project.provisioning_properties().extra_packages,
                                      "DOCKER_VOLUME_AUTO_EXTEND" => project.provisioning_properties().docker_volume_auto_extend,
                                      "KV_DB_FILE"                => project.provisioning_properties().kv_db_file,
                                      "KV_DB_FILE_CREATE_LINK"    => project.provisioning_properties().kv_db_file_create_link,
                                      "KV_RECORD_SEPARATOR"       => project.provisioning_properties().kv_record_separator,
                                      "KV_ASSIGNMENT_OPERATOR"    => project.provisioning_properties().kv_assignment_operator,
                                      "KV_DB_RECORDS"             => project.provisioning_properties().kv_db_records
                                    }
    end
  end
end
