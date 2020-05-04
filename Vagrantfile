Vagrant.configure("2") do |config|
  # ensuring windows hyper-v optional features are disabled when bringing up the machine
  if (ARGV[0] == "up" || ARGV[0] == "reload")
    if Vagrant::Util::Platform.windows? then
      if not system "powershell -ExecutionPolicy ByPass ./WindowsHyperVDeactivation.ps1"
        abort "Windows hyper-v deactivation has failed. Aborting."
      end
    end
  end

  config.vm.box = "metabarj0/DockerBox"
  config.vm.box_version = ">= 2.0.1"

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

  create_public_network = fetch_env_with_default('MACHINE_CREATE_PUBLIC_NETWORK', 0)
  if create_public_network == 1
    config.vm.network "public_network"
  end

  machine_forwarded_ports = fetch_env_with_default('MACHINE_FORWARDED_PORTS', '')
  if not machine_forwarded_ports.empty?
    forwarded_port_rules = machine_forwarded_ports.split(';')
    forwarded_port_rules.each { |rule|
      elements = rule.split

      config.vm.network "forwarded_port", guest: elements[1], host: elements[0], protocol: elements[2]
    }
  end

  # virtualbox provider specific configuration with defaults
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpus", fetch_env_with_default('MACHINE_CPU', 1)]
    v.customize ["modifyvm", :id, "--cpuexecutioncap", fetch_env_with_default('MACHINE_CPU_CAP', 100)]
    v.customize ["modifyvm", :id, "--memory", fetch_env_with_default('MACHINE_MEM', 1024)]
  end

  # shell provisioning
  config.vm.provision "shell", path: "provisioning/provision-from-host.sh",
                               env:
                               {
                                 "ZONEINFO_REGION" => fetch_env_with_default('ZONEINFO_REGION', 'UTC'),
                                 "ZONEINFO_CITY" => fetch_env_with_default('ZONEINFO_CITY', ''),
                                 "KEYMAP" => fetch_env_with_default('KEYMAP', 'us'),
                                 "KEYMAP_VARIANT" => fetch_env_with_default('KEYMAP_VARIANT', 'us'),
                                 "EXTRA_PACKAGES" => fetch_env_with_default('EXTRA_PACKAGES', ''),
                                 "DOCKER_VOLUME_AUTO_EXTEND" => fetch_env_with_default('DOCKER_VOLUME_AUTO_EXTEND', 1)
                               }
end