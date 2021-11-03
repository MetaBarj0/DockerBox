Vagrant.require_version ">= 2.2.0"
VAGRANTFILE_API_VERSION = "2"

require './modules/dockerbox'

DockerBox::ensure_windows_hyperv_is_disable_when_up_or_reload()
DockerBox::install_specified_plugins( %w( vagrant-vbguest ) )
configuration = DockerBox::read_configuration( 'config.yaml' )
DockerBox::install_extra_plugins_from_configuration( configuration )
DockerBox::setup_vagrant_provider_from_configuration( configuration )

Vagrant.configure( "2" ) do | config |
  # single machine setup configuration from config.yaml(.dist)
  hostname                = configuration[ 'single_machine' ][ 'hostname' ]
  machine_cpu             = configuration[ 'single_machine' ][ 'cpu' ]
  machine_cpu_cap         = configuration[ 'single_machine' ][ 'cpu_cap' ]
  machine_memory          = configuration[ 'single_machine' ][ 'memory' ]
  create_public_network   = configuration[ 'single_machine' ][ 'create_public_network' ]
  machine_forwarded_ports = configuration[ 'single_machine' ][ 'forwarded_ports' ]
  machine_synced_folders  = configuration[ 'single_machine' ][ 'synced_folders' ]
  ssh_command_extra_args  = configuration[ 'single_machine' ][ 'ssh_command_extra_args' ] || []

  # provisionning from config.yaml(.dist)
  provision_zoneinfo_region           = configuration[ 'provisioning' ][ 'zoneinfo_region' ]
  provision_zoneinfo_city             = configuration[ 'provisioning' ][ 'zoneinfo_city' ]
  provision_keymap                    = configuration[ 'provisioning' ][ 'keymap' ]
  provision_keymap_variant            = configuration[ 'provisioning' ][ 'keymap_variant' ]
  provision_docker_volume_auto_extend = configuration[ 'provisioning' ][ 'docker_volume_auto_extend' ] ? 1 : 0
  provision_extra_packages            = ( defined? configuration[ 'provisioning' ][ 'extra_packages' ].join ) ? configuration[ 'provisioning' ][ 'extra_packages' ].join(' ') : ''
  kv_db_file                          = configuration[ 'provisioning' ][ 'kv_db_file' ]
  kv_db_file_create_link              = configuration[ 'provisioning' ][ 'kv_db_file_create_link ' ] ? 1 : 0
  kv_record_separator                 = configuration[ 'provisioning' ][ 'kv_record_separator' ]
  kv_assignment_operator              = configuration[ 'provisioning' ][ 'kv_assignment_operator' ]
  kv_db_records                       = ( defined? configuration[ 'provisioning' ][ 'kv_db_records' ].join ) ? configuration[ 'provisioning' ][ 'kv_db_records' ].join( kv_record_separator ) : ''

  # multi-machine configuration from config.yaml(.dist)
  multi_machine_ip_addresses           = configuration[ 'multi_machine' ][ 'ip_addresses' ] || [ '' ]
  multi_machine_create_public_network  = configuration[ 'multi_machine' ][ 'create_public_network' ] || []
  multi_machine_shared_synced_folders  = configuration[ 'multi_machine' ][ 'shared_synced_folders' ] || []
  multi_machine_vm_prefixes            = configuration[ 'multi_machine' ][ 'vm_prefixes' ] || []
  multi_machine_hostname_prefixes      = configuration[ 'multi_machine' ][ 'hostname_prefixes' ] || []
  multi_machine_cpus                   = configuration[ 'multi_machine' ][ 'cpus' ]
  multi_machine_cpu_caps               = configuration[ 'multi_machine' ][ 'cpu_caps' ]
  multi_machine_memories               = configuration[ 'multi_machine' ][ 'memories' ]

  is_multi_machine_enabled = multi_machine_ip_addresses.length() > 1

  multi_machines_vm_prefix_map = {}

  multi_machines_hostname_prefix_map = {}

  # creating machines
  multi_machine_ip_addresses.each_with_index do | ip, multi_machine_index |
    machine_name = 'default'
    if is_multi_machine_enabled
      vm_prefix = multi_machine_vm_prefixes[ multi_machine_index ]

      if ( vm_prefix == nil ) || ( vm_prefix.empty? )
        vm_prefix = "machine"
      end

      if multi_machines_vm_prefix_map.include?( vm_prefix )
        multi_machines_vm_prefix_map[ vm_prefix ] = multi_machines_vm_prefix_map[ vm_prefix ] + 1
      else
        multi_machines_vm_prefix_map[ vm_prefix ] = 0
      end

      machine_name = "#{ vm_prefix }-#{ multi_machines_vm_prefix_map[ vm_prefix ] }"
    end

    config.ssh.username = "docker"

    if ssh_command_extra_args.length > 0
      config.ssh.extra_args = ssh_command_extra_args
    end

    config.vm.define "#{ machine_name }" do | machine |
      machine.vm.box = "metabarj0/DockerBox"
      machine.vm.box_version = ">= 3.0.0"

      if is_multi_machine_enabled
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
        machine.vm.hostname = hostname
      end

      # vagrant bug : not supported but should work as soon as vagrant has fixed its stuff
      is_unique_machine_public_network_enabled = create_public_network && ( not is_multi_machine_enabled )
      is_multi_machine_public_network_enabled = multi_machine_create_public_network[ multi_machine_index ]

      if is_unique_machine_public_network_enabled || is_multi_machine_public_network_enabled
        machine.vm.network "public_network"
      end

      # forwarding only applies on the first machine
      if( multi_machine_index == 0 )
        if machine_forwarded_ports
          machine_forwarded_ports.each { | rule |
            machine.vm.network "forwarded_port", guest: rule[ 'guest' ], host: rule[ 'host' ], protocol: rule[ 'protocol' ]
          }
        end
      end

      if machine_synced_folders
        has_multi_machine_synced_folders = multi_machine_shared_synced_folders[ multi_machine_index ]

        if ( not is_multi_machine_enabled ) || has_multi_machine_synced_folders
          machine_synced_folders.each { | machine_synced_folder |
            machine.vm.synced_folder machine_synced_folder[ 'host' ], machine_synced_folder[ 'guest' ]
          }
        end
      end

      if is_multi_machine_enabled
        machine.vm.network "private_network", ip: "#{ ip }"
      end

      current_machine_cpu = machine_cpu

      if is_multi_machine_enabled
        if ( not multi_machine_cpus[ multi_machine_index ] == nil ) && ( multi_machine_cpus[ multi_machine_index ] > 0 )
          current_machine_cpu = multi_machine_cpus[ multi_machine_index ]
        end
      end

      current_machine_cpu_cap = machine_cpu_cap

      if is_multi_machine_enabled
        if ( not multi_machine_cpu_caps[ multi_machine_index ] == nil ) && ( multi_machine_cpu_caps[ multi_machine_index ] > 0 )
          current_machine_cpu_cap = multi_machine_cpu_caps[ multi_machine_index ]
        end
      end

      current_machine_memory = machine_memory

      if is_multi_machine_enabled
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
                                      "ZONEINFO_REGION"           => provision_zoneinfo_region,
                                      "ZONEINFO_CITY"             => provision_zoneinfo_city,
                                      "KEYMAP"                    => provision_keymap,
                                      "KEYMAP_VARIANT"            => provision_keymap_variant,
                                      "EXTRA_PACKAGES"            => provision_extra_packages,
                                      "DOCKER_VOLUME_AUTO_EXTEND" => provision_docker_volume_auto_extend,
                                      "KV_DB_FILE"                => kv_db_file,
                                      "KV_DB_FILE_CREATE_LINK"    => kv_db_file_create_link,
                                      "KV_RECORD_SEPARATOR"       => kv_record_separator,
                                      "KV_ASSIGNMENT_OPERATOR"    => kv_assignment_operator,
                                      "KV_DB_RECORDS"             => kv_db_records
                                    }

    end
  end
end
