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
      def ssh_command_extra_args() @configuration[ 'single_machine' ][ 'ssh_command_extra_args' ] end;
    end.new( configuration )
  end

  def self.get_provision_properties( configuration )
    return Class.new do
      def initialize( configuration )
        @configuration = configuration
      end

      def zoneinfo_region()           @configuration[ 'provisioning' ][ 'zoneinfo_region' ] end;
      def zoneinfo_city()             @configuration[ 'provisioning' ][ 'zoneinfo_city' ] end;
      def keymap()                    @configuration[ 'provisioning' ][ 'keymap' ] end;
      def keymap_variant()            @configuration[ 'provisioning' ][ 'keymap_variant' ] end;
      def docker_volume_auto_extend() @configuration[ 'provisioning' ][ 'docker_volume_auto_extend' ] ? 1 : 0 end;
      def extra_packages()            ( defined? @configuration[ 'provisioning' ][ 'extra_packages' ].join ) ? @configuration[ 'provisioning' ][ 'extra_packages' ].join(' ') : '' end;
      def kv_db_file()                @configuration[ 'provisioning' ][ 'kv_db_file' ] end;
      def kv_db_file_create_link()    @configuration[ 'provisioning' ][ 'kv_db_file_create_link ' ] ? 1 : 0 end;
      def kv_record_separator()       @configuration[ 'provisioning' ][ 'kv_record_separator' ] end;
      def kv_assignment_operator()    @configuration[ 'provisioning' ][ 'kv_assignment_operator' ] end;
      def kv_db_records()             ( defined? @configuration[ 'provisioning' ][ 'kv_db_records' ].join ) ? @configuration[ 'provisioning' ][ 'kv_db_records' ].join( kv_record_separator ) : '' end;
    end.new( configuration )
  end

  def self.get_multi_machine_properties( configuration )
    return Class.new do
      def initialize( configuration )
        @configuration = configuration
      end

      def ip_addresses()           @configuration[ 'multi_machine' ][ 'ip_addresses' ] || [ '' ] end;
      def create_public_network()  @configuration[ 'multi_machine' ][ 'create_public_network' ] || [] end;
      def shared_synced_folders()  @configuration[ 'multi_machine' ][ 'shared_synced_folders' ] || [] end;
      def vm_prefixes()            @configuration[ 'multi_machine' ][ 'vm_prefixes' ] || [] end;
      def hostname_prefixes()      @configuration[ 'multi_machine' ][ 'hostname_prefixes' ] || [] end;
      def cpus()                   @configuration[ 'multi_machine' ][ 'cpus' ] end;
      def cpu_caps()               @configuration[ 'multi_machine' ][ 'cpu_caps' ] end;
      def memories()               @configuration[ 'multi_machine' ][ 'memories' ] end;
    end.new( configuration )
  end

  def self.is_multi_machine_enabled( config_file_name )
    configuration = DockerBox::read_configuration( config_file_name )
    multi_machine = DockerBox::get_multi_machine_properties( configuration )

    return multi_machine.ip_addresses.length() > 1
  end

  class MultiMachineVmPrefixBuilder
    def initialize( config_file_name )
      @config_file_name = config_file_name
      configuration = DockerBox::read_configuration( config_file_name )
      @multi_machine = DockerBox::get_multi_machine_properties( configuration )
      @multi_machines_vm_prefix_map = {}
    end

    def get_next_vm_prefix( multi_machine_index )
      machine_name = 'default'

      if not DockerBox::is_multi_machine_enabled( @config_file_name )
        return machine_name
      end

      vm_prefix = @multi_machine.vm_prefixes[ multi_machine_index ]

      if ( vm_prefix == nil ) || ( vm_prefix.empty? )
        vm_prefix = "machine"
      end

      if @multi_machines_vm_prefix_map.include?( vm_prefix )
        @multi_machines_vm_prefix_map[ vm_prefix ] = @multi_machines_vm_prefix_map[ vm_prefix ] + 1
      else
        @multi_machines_vm_prefix_map[ vm_prefix ] = 0
      end

      return "#{ vm_prefix }-#{ @multi_machines_vm_prefix_map[ vm_prefix ] }"
    end
  end

  class MultiMachineHostnameBuilder
    def initialize( config_file_name )
      @config_file_name = config_file_name
      configuration = DockerBox::read_configuration( config_file_name )
      @single_machine = DockerBox::get_single_machine_properties( configuration )
      @multi_machine = DockerBox::get_multi_machine_properties( configuration )
      @multi_machines_hostname_prefix_map = {}
    end

    def get_next_hostname( multi_machine_index )
      hostname = @single_machine.hostname

      if DockerBox::is_multi_machine_enabled( @config_file_name )
        hostname_prefix = @multi_machine.hostname_prefixes[ multi_machine_index ]

        if ( hostname_prefix == nil ) || hostname_prefix.empty?
          hostname_prefix = @single_machine.hostname
        end

        if @multi_machines_hostname_prefix_map.include?( hostname_prefix )
          @multi_machines_hostname_prefix_map[ hostname_prefix ] = @multi_machines_hostname_prefix_map[ hostname_prefix ] + 1
        else
          @multi_machines_hostname_prefix_map[ hostname_prefix ] = 0
        end

        hostname = "#{ hostname_prefix }-#{ @multi_machines_hostname_prefix_map[ hostname_prefix ] }"
      end
    end
  end

  def self.has_public_network( config_file_name, multi_machine_index )
    configuration = DockerBox::read_configuration( config_file_name )
    single_machine = DockerBox::get_single_machine_properties( configuration )
    multi_machine = DockerBox::get_multi_machine_properties( configuration )

    # vagrant bug : not supported but should work as soon as vagrant has fixed its stuff
    is_unique_machine_public_network_enabled = single_machine.create_public_network && ( not is_multi_machine_enabled )
    is_multi_machine_public_network_enabled = multi_machine.create_public_network[ multi_machine_index ]

    return is_unique_machine_public_network_enabled || is_multi_machine_public_network_enabled
  end

  def self.can_setup_forwarded_ports( config_file_name, multi_machine_index )
    if multi_machine_index > 0
      return false
    end

    configuration = DockerBox::read_configuration( config_file_name )
    single_machine = DockerBox::get_single_machine_properties( configuration )

    return single_machine.forwarded_ports && single_machine.forwarded_ports.length > 0
  end

  def self.get_forwarded_ports( config_file_name, multi_machine_index )
    configuration = DockerBox::read_configuration( config_file_name )
    single_machine = DockerBox::get_single_machine_properties( configuration )

    return DockerBox::can_setup_forwarded_ports( config_file_name, multi_machine_index ) ? single_machine.forwarded_ports : []
  end

  def self.multi_machine_have_shared_synced_folders( multi_machine_index )
    configuration = DockerBox::read_configuration( config_file_name )
    multi_machine = DockerBox::get_multi_machine_properties( configuration )

    return multi_machine.shared_synced_folders[ multi_machine_index ]
  end

  def self.get_synced_folders( config_file_name, multi_machine_index )
    configuration = DockerBox::read_configuration( config_file_name )
    single_machine = DockerBox::get_single_machine_properties( configuration )

    if not single_machine.synced_folders
      return []
    end

    if ( not DockerBox::is_multi_machine_enabled ) || DockerBox::multi_machine_have_shared_synced_folders( multi_machine_index )
      return single_machine.synced_folders
    end

    return []
  end

  def self.get_machine_cpu_count( config_file_name, multi_machine_index )
    configuration = DockerBox::read_configuration( config_file_name )
    single_machine = DockerBox::get_single_machine_properties( configuration )
    multi_machine = DockerBox::get_multi_machine_properties( configuration )

    if not DockerBox::is_multi_machine_enabled( 'config.yaml' )
      return single_machine.cpu
    end

    if multi_machine.cpus[ multi_machine_index ] && ( multi_machine.cpus[ multi_machine_index ] > 0 )
      return multi_machine.cpus[ multi_machine_index ]
    end
  end

  def self.get_machine_cpu_cap( config_file_name, multi_machine_index )
    configuration = DockerBox::read_configuration( config_file_name )
    single_machine = DockerBox::get_single_machine_properties( configuration )
    multi_machine = DockerBox::get_multi_machine_properties( configuration )

    if not DockerBox::is_multi_machine_enabled( 'config.yaml' )
      return single_machine.cpu_cap
    end

    if multi_machine.cpu_caps[ multi_machine_index ] && ( multi_machine.cpu_caps[ multi_machine_index ] > 0 )
      return multi_machine.cpu_caps[ multi_machine_index ]
    end
  end

  def self.get_machine_memory( config_file_name, multi_machine_index )
    configuration = DockerBox::read_configuration( config_file_name )
    single_machine = DockerBox::get_single_machine_properties( configuration )
    multi_machine = DockerBox::get_multi_machine_properties( configuration )

    if not DockerBox::is_multi_machine_enabled( 'config.yaml' )
      return single_machine.memory
    end

    if multi_machine.memories[ multi_machine_index ] && ( multi_machine.memories[ multi_machine_index ] > 0 )
      return multi_machine.memories[ multi_machine_index ]
    end
  end
end