Vagrant.configure("2") do |config|
  config.vm.box = "metabarj0/DockerBox"
  config.vm.box_version = "1.0.0"

  required_plugins = %w(vagrant-env)

  # install all required plugins then, restart vagrant process
  plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
  if not plugins_to_install.empty?
    puts "Installing plugins: #{plugins_to_install.join(' ')}"
    if system "vagrant plugin install #{plugins_to_install.join(' ')}"
      exec "vagrant #{ARGV.join(' ')}"
    else
      abort "Installation of one or more plugins has failed. Aborting."
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
  
  $vagrant_provider = fetch_env_with_default('VAGRANT_DEFAULT_PROVIDER', 'virtualbox')

  # this machine is only useable with hyperv provider
  if $vagrant_provider != "virtualbox"
    abort "Cannot up DockerBox with the #{$vagrant_provider} provider. Only 'virtualbox' provider is supported"
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
                                 "NTP_SYNC" => fetch_env_with_default('NTP_SYNC', 1),
                                 "ZONEINFO_REGION" => fetch_env_with_default('ZONEINFO_REGION', 'UTC'),
                                 "ZONEINFO_CITY" => fetch_env_with_default('ZONEINFO_CITY', ''),
                                 "LOCALES" => fetch_env_with_default('LOCALES', 'en_US.UTF-8'),
                                 "LANG" => fetch_env_with_default('LANG', 'en_US'),
                                 "KEYMAP" => fetch_env_with_default('KEYMAP', 'us')
                               }
end