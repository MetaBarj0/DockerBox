require 'yaml'

module DockerBox
  def self.repair_plugin_dependencies()
    if system "vagrant plugin list"
      return true
    end

    if not system "vagrant plugin repair"
      return system "vagrant plugin expunge --reinstall "
    end

    return true
  end

  def self.install_plugin_dependencies( plugins )
    repair_plugin_dependencies()

    system "vagrant plugin install #{ plugins.join( ' ' ) }"
    system "vagrant plugin update"
  end

  def self.ensure_windows_hyperv_is_disable_when_up_or_reload()
    if( ARGV[ 0 ] == "up" || ARGV[ 0 ] == "reload" )
      if Vagrant::Util::Platform.windows? then
        if not system "powershell -ExecutionPolicy ByPass ./WindowsHyperVDeactivation.ps1"
          abort "Windows hyper-v deactivation has failed. Aborting."
        end
      end
    end
  end

  def self.install_specified_plugins( required_plugins )
    plugins_to_install = required_plugins.select { | plugin | not Vagrant.has_plugin? plugin }

    if not plugins_to_install.empty?
      puts "Installing specified plugins: #{ plugins_to_install.join( ' ' ) }"
      if install_plugin_dependencies( plugins_to_install )
        exec "vagrant #{ ARGV.join( ' ' ) }"
      else
        abort "Installation of one or more specified plugins or their dependencies have failed. Aborting."
      end
    end
  end

  def self.read_configuration( config_file_name )
    if not FileTest::file?( config_file_name )
      puts "Information, no 'config.yaml' file found. Default value wile be used."
      puts "Consider to create your own config.yaml file from the config.yaml.dist "
      puts "template."

      return YAML.load_file( "#{ config_file_name }.dist" )
    end

    return YAML.load_file( config_file_name )
  end

  def self.install_extra_plugins_from_configuration( configuration )
    extra_plugins = configuration[ 'vagrant' ][ 'extra_plugins' ]

    if not extra_plugins
      return
    end

    install_specified_plugins( extra_plugins )
  end

  def self.setup_vagrant_provider_from_configuration( configuration )
    vagrant_provider = configuration[ 'vagrant' ][ 'default_provider' ]

    if vagrant_provider != "virtualbox"
      abort "Cannot up DockerBox with the #{ vagrant_provider } provider. Only 'virtualbox' provider is supported"
    end

    ENV[ 'VAGRANT_DEFAULT_PROVIDER' ] = vagrant_provider
  end

  def self.get_single_machine_properties( configuration )
    return Class.new do
      def initialize( configuration )
        @configuration = configuration
      end

      def hostname()               @configuration[ 'single_machine' ][ 'hostname' ] end;
      def cpu()                    @configuration[ 'single_machine' ][ 'cpu' ] end;
      def cpu_cap()                @configuration[ 'single_machine' ][ 'cpu_cap' ] end;
      def memory()                 @configuration[ 'single_machine' ][ 'memory' ] end;
      def create_public_network()  @configuration[ 'single_machine' ][ 'create_public_network' ] end;
      def forwarded_ports()        @configuration[ 'single_machine' ][ 'forwarded_ports' ] end;
      def synced_folders()         @configuration[ 'single_machine' ][ 'synced_folders' ] end;
      def ssh_command_extra_args() @configuration[ 'single_machine' ][ 'ssh_command_extra_args' ] || [] end;
    end.new( configuration )
  end
end