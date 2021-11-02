Vagrant.require_version ">= 2.2.0"
VAGRANTFILE_API_VERSION = "2"

require 'yaml'

Vagrant.configure( "2" ) do | config |
  # ensuring windows hyper-v optional features are disabled when bringing up the machine
  if( ARGV[ 0 ] == "up" || ARGV[ 0 ] == "reload" )
    if Vagrant::Util::Platform.windows? then
      if not system "powershell -ExecutionPolicy ByPass ./WindowsHyperVDeactivation.ps1"
        abort "Windows hyper-v deactivation has failed. Aborting."
      end
    end
  end

  def repair_plugin_dependencies()
    if system "vagrant plugin list"
      return true
    end

    if not system "vagrant plugin repair"
      return system "vagrant plugin expunge --reinstall "
    end

    return true
  end

  def install_plugin_dependencies( plugins )
    repair_plugin_dependencies()

    system "vagrant plugin install #{ plugins.join( ' ' ) }"
    system "vagrant plugin update"
  end

  # install all required plugins then, restart vagrant process
  required_plugins = %w( vagrant-vbguest )
  plugins_to_install = required_plugins.select { | plugin | not Vagrant.has_plugin? plugin }

  if not plugins_to_install.empty?
    puts "Installing required plugins: #{ plugins_to_install.join( ' ' ) }"
    if install_plugin_dependencies( plugins_to_install )
      exec "vagrant #{ ARGV.join( ' ' ) }"
    else
      abort "Installation of one or more required plugins has failed. Aborting."
    end
  end

  config_file_name = 'config.yaml'

  if not FileTest::file?( './config.yaml' )
    puts "Information, no 'config.yaml' file found. Default value wile be used."
    puts "Consider to create your own config.yaml file from the config.yaml.dist "
    puts "template."

    config_file_name = "#{ config_file_name }.dist"
  end

  configuration = YAML.load_file( config_file_name )

  # install all extra plugins then, restart vagrant process
  extra_plugins = configuration[ 'vagrant' ][ 'extra_plugins' ]

  extra_plugins_to_install = ''
  if extra_plugins
    extra_plugins_to_install = extra_plugins.select { | plugin | not Vagrant.has_plugin? plugin }
  end

  if not extra_plugins_to_install.empty?
    puts "Installing extra plugins: #{ extra_plugins_to_install.join( ' ' ) }"
    if install_plugin_dependencies( extra_plugins_to_install )
      exec "vagrant #{ ARGV.join( ' ' ) }"
    else
      abort "Installation of one or more extra plugins has failed. Aborting."
    end
  end

  vagrant_provider = configuration[ 'vagrant' ][ 'default_provider' ]

  if vagrant_provider != "virtualbox"
    abort "Cannot up DockerBox with the #{ vagrant_provider } provider. Only 'virtualbox' provider is supported"
  end

  ENV[ 'VAGRANT_DEFAULT_PROVIDER' ] = vagrant_provider

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
  multi_machine_ip_addresses           = configuration[ 'multi_machine_ip_addresses' ] || [ '' ]
  multi_machines_create_public_network = configuration[ 'multi_machines_create_public_network' ] || []
  multi_machines_share_synced_folders  = configuration[ 'multi_machines_share_synced_folders' ] || []
  multi_machines_vm_prefixes           = configuration[ 'multi_machines_vm_prefixes' ] || []
  multi_machines_hostname_prefixes     = configuration[ 'multi_machines_hostname_prefixes' ] || []
  multi_machines_cpu                   = configuration[ 'multi_machines_cpu' ]
  multi_machines_cpu_cap               = configuration[ 'multi_machines_cpu_cap' ]
  multi_machines_memory                = configuration[ 'multi_machines_memory' ]

  is_multi_machine_enabled = multi_machine_ip_addresses.length() > 1

  multi_machines_vm_prefix_map = {}

  multi_machines_hostname_prefix_map = {}

  # creating machines
  multi_machine_ip_addresses.each_with_index do | ip, multi_machine_index |
    machine_name = 'default'
    if is_multi_machine_enabled
      vm_prefix = multi_machines_vm_prefixes[ multi_machine_index ]

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
        hostname_prefix = multi_machines_hostname_prefixes[ multi_machine_index ]

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
      is_multi_machine_public_network_enabled = multi_machines_create_public_network[ multi_machine_index ]

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
        has_multi_machine_synced_folders = multi_machines_share_synced_folders[ multi_machine_index ]

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
        if ( not multi_machines_cpu[ multi_machine_index ] == nil ) && ( multi_machines_cpu[ multi_machine_index ] > 0 )
          current_machine_cpu = multi_machines_cpu[ multi_machine_index ]
        end
      end

      current_machine_cpu_cap = machine_cpu_cap

      if is_multi_machine_enabled
        if ( not multi_machines_cpu_cap[ multi_machine_index ] == nil ) && ( multi_machines_cpu_cap[ multi_machine_index ] > 0 )
          current_machine_cpu_cap = multi_machines_cpu_cap[ multi_machine_index ]
        end
      end

      current_machine_memory = machine_memory

      if is_multi_machine_enabled
        if ( not multi_machines_memory[ multi_machine_index ] == nil ) && ( multi_machines_memory[ multi_machine_index ] > 0 )
          current_machine_memory = multi_machines_memory[ multi_machine_index ]
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
