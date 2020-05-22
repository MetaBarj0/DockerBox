Vagrant.configure("2") do |config|
  # ensuring windows hyper-v optional features are disabled when bringing up the machine
  if (ARGV[0] == "up" || ARGV[0] == "reload")
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

  def install_plugin_dependencies(plugins)
    repair_plugin_dependencies()

    system "vagrant plugin install #{plugins.join(' ')}"
    system "vagrant plugin update"
  end

  # install all required plugins then, restart vagrant process
  required_plugins = %w(vagrant-vbguest vagrant-env)
  plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }

  if not plugins_to_install.empty?
    puts "Installing required plugins: #{plugins_to_install.join(' ')}"
    if install_plugin_dependencies(plugins_to_install)
      exec "vagrant #{ARGV.join(' ')}"
    else
      abort "Installation of one or more required plugins has failed. Aborting."
    end
  end

  # enable vagrant-env plugin, reading .env file
  config.env.enable

  if not FileTest::file?('./.env')
    puts "Information, no '.env' file found. Default value wile be used."
    puts "Consider to create your own .env file from the .env.dist template"
  end
  
  # utility to fetch environmental with a default value
  def fetch_env_with_default(key, default)
    return (ENV.has_key?(key) && ENV[key] != "") ? ENV[key] : default
  end

  # install all extra plugins then, restart vagrant process
  extra_plugins = fetch_env_with_default('VAGRANT_EXTRA_PLUGINS', '')

  extra_plugins_to_install = ''
  if not extra_plugins.empty?
    extra_plugins_to_install = extra_plugins.split.select { |plugin| not Vagrant.has_plugin? plugin }
  end

  if not extra_plugins_to_install.empty?
    puts "Installing extra plugins: #{extra_plugins_to_install.join(' ')}"
    if install_plugin_dependencies(extra_plugins_to_install)
      exec "vagrant #{ARGV.join(' ')}"
    else
      abort "Installation of one or more extra plugins has failed. Aborting."
    end
  end

  vagrant_provider = fetch_env_with_default('VAGRANT_DEFAULT_PROVIDER', 'virtualbox')

  if vagrant_provider != "virtualbox"
    abort "Cannot up DockerBox with the #{vagrant_provider} provider. Only 'virtualbox' provider is supported"
  end

  multi_machines = fetch_env_with_default('MULTI_MACHINES', '')
  multi_machine_ips = [ '' ]
  if not multi_machines.empty?
    multi_machine_ips = multi_machines.split
  end

  is_multi_machine_enabled = multi_machine_ips.length() > 1

  multi_machines_create_public_network = fetch_env_with_default('MULTI_MACHINES_CREATE_PUBLIC_NETWORK', '0')
  is_multi_machine_public_network_enabled = ( multi_machines_create_public_network == '1' )

  multi_machines_share_synced_folders = fetch_env_with_default('MULTI_MACHINES_SHARE_SYNCED_FOLDERS', '0')
  are_multi_machine_sharing_synced_folders = ( multi_machines_share_synced_folders == '1' )

  multi_machine_ips.each_with_index do |ip, multi_machine_index|
    machine_name = 'default'
    if is_multi_machine_enabled
      machine_name = "machine-#{multi_machine_index}"
    end

    config.vm.define "#{machine_name}" do |machine|
      machine.vm.box = "metabarj0/DockerBox"
      machine.vm.box_version = ">= 2.0.1"

      hostname = fetch_env_with_default('MACHINE_HOSTNAME', 'docker-box')
      machine.vm.hostname = hostname

      if is_multi_machine_enabled
        machine.vm.hostname = "#{hostname}-#{multi_machine_index}"
      end

      create_public_network = fetch_env_with_default('MACHINE_CREATE_PUBLIC_NETWORK', '0')
      if ( ( create_public_network == '1' ) && ( multi_machine_index == 0 ) ) || ( ( multi_machine_index > 0 ) && is_multi_machine_public_network_enabled )
        machine.vm.network "public_network"
      end

      if (multi_machine_index == 0)
        machine_forwarded_ports = fetch_env_with_default('MACHINE_FORWARDED_PORTS', '')
        if not machine_forwarded_ports.empty?
          forwarded_port_rules = machine_forwarded_ports.split(';')
          forwarded_port_rules.each { |rule|
            elements = rule.split

            machine.vm.network "forwarded_port", guest: elements[1], host: elements[0], protocol: elements[2]
          }
        end
      end

      machine_synced_folders = fetch_env_with_default('MACHINE_SYNCED_FOLDERS', '')
      if not machine_synced_folders.empty?
        if (  multi_machine_index == 0 ) || are_multi_machine_sharing_synced_folders
          machine_synced_folder_list = machine_synced_folders.split(';')
          machine_synced_folder_list.each { |folder|
            elements = folder.split

            machine.vm.synced_folder elements[0], elements[1]
          }
        end
      end

      if is_multi_machine_enabled
        machine.vm.network "private_network", ip: "#{ip}"
      end

      # virtualbox provider specific configuration with defaults
      machine.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--cpus", fetch_env_with_default('MACHINE_CPU', 1)]
        v.customize ["modifyvm", :id, "--cpuexecutioncap", fetch_env_with_default('MACHINE_CPU_CAP', 100)]
        v.customize ["modifyvm", :id, "--memory", fetch_env_with_default('MACHINE_MEM', 1024)]
      end

      # shell provisioning
      machine.vm.provision "shell", path: "provisioning/provision-from-host.sh",
                                env:
                                {
                                  "ZONEINFO_REGION" => fetch_env_with_default('ZONEINFO_REGION', 'UTC'),
                                  "ZONEINFO_CITY" => fetch_env_with_default('ZONEINFO_CITY', ''),
                                  "KEYMAP" => fetch_env_with_default('KEYMAP', 'us'),
                                  "KEYMAP_VARIANT" => fetch_env_with_default('KEYMAP_VARIANT', 'us'),
                                  "EXTRA_PACKAGES" => fetch_env_with_default('EXTRA_PACKAGES', ''),
                                  "DOCKER_VOLUME_AUTO_EXTEND" => fetch_env_with_default('DOCKER_VOLUME_AUTO_EXTEND', 1),
                                  "SSH_SECRET_KEY" => fetch_env_with_default('SSH_SECRET_KEY', ''),
                                  "SSH_PUBLIC_KEY" => fetch_env_with_default('SSH_PUBLIC_KEY', '')
                                }

    end
  end
end