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
  required_plugins = %w( vagrant-vbguest vagrant-env )
  plugins_to_install = required_plugins.select { | plugin | not Vagrant.has_plugin? plugin }

  if not plugins_to_install.empty?
    puts "Installing required plugins: #{ plugins_to_install.join( ' ' ) }"
    if install_plugin_dependencies( plugins_to_install )
      exec "vagrant #{ ARGV.join( ' ' ) }"
    else
      abort "Installation of one or more required plugins has failed. Aborting."
    end
  end

  # enable vagrant-env plugin, reading .env file
  config.env.enable

  if not FileTest::file?( './.env' )
    puts "Information, no '.env' file found. Default value wile be used."
    puts "Consider to create your own .env file from the .env.dist template"
  end
  
  # utility to fetch environmental with a default value
  def fetch_env_with_default( key, default )
    return ( ENV.has_key?( key ) && ENV[ key ] != "" ) ? ENV[ key ] : default
  end

  # install all extra plugins then, restart vagrant process
  extra_plugins = fetch_env_with_default( 'VAGRANT_EXTRA_PLUGINS', '' )

  extra_plugins_to_install = ''
  if not extra_plugins.empty?
    extra_plugins_to_install = extra_plugins.split.select { | plugin | not Vagrant.has_plugin? plugin }
  end

  if not extra_plugins_to_install.empty?
    puts "Installing extra plugins: #{ extra_plugins_to_install.join( ' ' ) }"
    if install_plugin_dependencies( extra_plugins_to_install )
      exec "vagrant #{ ARGV.join( ' ' ) }"
    else
      abort "Installation of one or more extra plugins has failed. Aborting."
    end
  end

  vagrant_provider = fetch_env_with_default( 'VAGRANT_DEFAULT_PROVIDER', 'virtualbox' )

  if vagrant_provider != "virtualbox"
    abort "Cannot up DockerBox with the #{ vagrant_provider } provider. Only 'virtualbox' provider is supported"
  end

  # machine configuration from env
  hostname                = fetch_env_with_default( 'MACHINE_HOSTNAME', 'docker-box' )
  create_public_network   = fetch_env_with_default( 'MACHINE_CREATE_PUBLIC_NETWORK', '0' )
  machine_forwarded_ports = fetch_env_with_default( 'MACHINE_FORWARDED_PORTS', '' )
  machine_synced_folders  = fetch_env_with_default( 'MACHINE_SYNCED_FOLDERS', '' )
  machine_cpu             = fetch_env_with_default( 'MACHINE_CPU', 1 )
  machine_cpu_cap         = fetch_env_with_default( 'MACHINE_CPU_CAP', 100 )
  machine_mem             = fetch_env_with_default( 'MACHINE_MEM', 1024 )

  # machine provisionning from env
  provision_zoneinfo_region           = fetch_env_with_default( 'ZONEINFO_REGION', 'UTC' )
  provision_zoneinfo_city             = fetch_env_with_default( 'ZONEINFO_CITY', '' )
  provision_keymap                    = fetch_env_with_default( 'KEYMAP', 'us' )
  provision_keymap_variant            = fetch_env_with_default( 'KEYMAP_VARIANT', 'us' )
  provision_extra_packages            = fetch_env_with_default( 'EXTRA_PACKAGES', '' )
  provision_docker_volume_auto_extend = fetch_env_with_default( 'DOCKER_VOLUME_AUTO_EXTEND', 1 )

  # interaction with the machine
  ssh_command_extra_args = fetch_env_with_default( 'SSH_COMMAND_EXTRA_ARGS', '' )

  # multi-machine configuration from env
  multi_machines                       = fetch_env_with_default( 'MULTI_MACHINES', '' )
  multi_machines_create_public_network = fetch_env_with_default( 'MULTI_MACHINES_CREATE_PUBLIC_NETWORK', '' )
  multi_machines_share_synced_folders  = fetch_env_with_default( 'MULTI_MACHINES_SHARE_SYNCED_FOLDERS', '' )
  multi_machines_vm_prefix             = fetch_env_with_default( 'MULTI_MACHINES_VM_PREFIX', '' )
  multi_machines_hostname_prefix       = fetch_env_with_default( 'MULTI_MACHINES_HOSTNAME_PREFIX', '' )
  multi_machines_cpu                   = fetch_env_with_default( 'MULTI_MACHINES_CPU', '' )
  multi_machines_cpu_cap               = fetch_env_with_default( 'MULTI_MACHINES_CPU_CAP', '' )
  multi_machines_mem                   = fetch_env_with_default( 'MULTI_MACHINES_MEM', '' )

  ssh_args = []
  if not ssh_command_extra_args.empty?
    ssh_args = ssh_command_extra_args.split( ',' )
  end

  multi_machine_ips = [ '' ] # by default one machine, without any IP
  if not multi_machines.empty?
    multi_machine_ips = multi_machines.split
  end

  is_multi_machine_enabled = multi_machine_ips.length() > 1

  # vagrant bug : the public_network support is broken, do not use
  multi_machines_create_public_network_array = []
  if not multi_machines_create_public_network.empty?
    multi_machines_create_public_network_array = multi_machines_create_public_network.split
  end

  are_multi_machine_sharing_synced_folders_array = []
  if not multi_machines_share_synced_folders.empty?
    are_multi_machine_sharing_synced_folders_array = multi_machines_share_synced_folders.split
  end

  multi_machines_vm_prefix_array = []
  if not multi_machines_vm_prefix.empty?
    multi_machines_vm_prefix_array = multi_machines_vm_prefix.split
  end

  multi_machines_hostname_prefix_array = []
  if not multi_machines_hostname_prefix.empty?
    multi_machines_hostname_prefix_array = multi_machines_hostname_prefix.split
  end

  multi_machines_cpu_array = []
  if not multi_machines_cpu.empty?
    multi_machines_cpu_array = multi_machines_cpu.split
  end

  multi_machines_cpu_cap_array = []
  if not multi_machines_cpu_cap.empty?
    multi_machines_cpu_cap_array = multi_machines_cpu_cap.split
  end

  multi_machines_mem_array = []
  if not multi_machines_mem.empty?
    multi_machines_mem_array = multi_machines_mem.split
  end

  multi_machines_vm_prefix_map = {}

  multi_machines_hostname_prefix_map = {}

  # creating machines
  multi_machine_ips.each_with_index do | ip, multi_machine_index |
    machine_name = 'default'
    if is_multi_machine_enabled
      vm_prefix = multi_machines_vm_prefix_array[ multi_machine_index ]

      if ( vm_prefix == nil ) || ( vm_prefix.empty? )
        vm_prefix= "machine"
      end

      if multi_machines_vm_prefix_map.include?( vm_prefix )
        multi_machines_vm_prefix_map[ vm_prefix ] = multi_machines_vm_prefix_map[ vm_prefix ] + 1
      else
        multi_machines_vm_prefix_map[ vm_prefix ] = 0
      end

      machine_name = "#{ vm_prefix }-#{ multi_machines_vm_prefix_map[ vm_prefix ] }"
    end

    config.ssh.username = "docker"

    if ssh_args.length > 0
      config.ssh.extra_args = ssh_args
    end

    config.vm.define "#{ machine_name }" do | machine |
      machine.vm.box = "metabarj0/DockerBox"
      machine.vm.box_version = ">= 2.2.0"

      if is_multi_machine_enabled
        hostname_prefix = multi_machines_hostname_prefix_array[ multi_machine_index ]

        if ( hostname_prefix == nil ) || hostname_prefix.empty?
          hostname_prefix = hostname
        end

        if multi_machines_hostname_prefix_map.include?( hostname_prefix )
          multi_machines_hostname_prefix_map[ hostname_prefix ] = multi_machines_hostname_prefix_map[ hostname_prefix ] + 1
        else
          multi_machines_hostname_prefix_map[ hostname_prefix ] = 0
        end

        machine.vm.hostname = "#{ hostname_prefix }-#{multi_machines_hostname_prefix_map[ hostname_prefix ]}"
      else
        machine.vm.hostname = hostname
      end

      # vagrant bug : not supported but should work as soon as vagrant has fixed its stuff
      is_unique_machine_public_network_enabled = ( create_public_network == '1' ) && ( not is_multi_machine_enabled )
      is_multi_machine_public_network_enabled = ( multi_machines_create_public_network_array[ multi_machine_index ] == '1' )

      if is_unique_machine_public_network_enabled || is_multi_machine_public_network_enabled
        machine.vm.network "public_network"
      end

      # forwarding only applies on the first machine
      if( multi_machine_index == 0 )
        if not machine_forwarded_ports.empty?
          forwarded_port_rules = machine_forwarded_ports.split( ';' )
          forwarded_port_rules.each { | rule |
            elements = rule.split

            machine.vm.network "forwarded_port", guest: elements[ 1 ], host: elements[ 0 ], protocol: elements[ 2 ]
          }
        end
      end

      if not machine_synced_folders.empty?
        has_multi_machine_synced_folders = ( are_multi_machine_sharing_synced_folders_array[ multi_machine_index ] == '1' )

        if ( not is_multi_machine_enabled ) || has_multi_machine_synced_folders
          machine_synced_folder_list = machine_synced_folders.split( ';' )
          machine_synced_folder_list.each { | folder |
            elements = folder.split
            machine.vm.synced_folder elements[ 0 ], elements[ 1 ]
          }
        end
      end

      if is_multi_machine_enabled
        machine.vm.network "private_network", ip: "#{ ip }"
      end

      current_machine_cpu = machine_cpu

      if is_multi_machine_enabled
        if ( not multi_machines_cpu_array[ multi_machine_index ] == nil ) && ( multi_machines_cpu_array[ multi_machine_index ].to_i > 0 )
          current_machine_cpu = multi_machines_cpu_array[ multi_machine_index ]
        end
      end

      current_machine_cpu_cap = machine_cpu_cap

      if is_multi_machine_enabled
        if ( not multi_machines_cpu_cap_array[ multi_machine_index ] == nil ) && ( multi_machines_cpu_cap_array[ multi_machine_index ].to_i > 0 )
          current_machine_cpu_cap = multi_machines_cpu_cap_array[ multi_machine_index ]
        end
      end

      current_machine_mem = machine_mem

      if is_multi_machine_enabled
        if ( not multi_machines_mem_array[ multi_machine_index ] == nil ) && ( multi_machines_mem_array[ multi_machine_index ].to_i > 0 )
          current_machine_mem = multi_machines_mem_array[ multi_machine_index ]
        end
      end

      # virtualbox provider specific configuration with defaults
      machine.vm.provider "virtualbox" do | v |
        v.customize [ "modifyvm", :id, "--cpus", current_machine_cpu ]
        v.customize [ "modifyvm", :id, "--cpuexecutioncap", current_machine_cpu_cap ]
        v.customize [ "modifyvm", :id, "--memory", current_machine_mem ]
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
                                      "DOCKER_VOLUME_AUTO_EXTEND" => provision_docker_volume_auto_extend
                                    }

    end
  end
end

