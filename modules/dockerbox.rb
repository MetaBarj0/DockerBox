require 'yaml'

module DockerBox
  class VagrantProject
    def initialize( config_file_name )
      @configuration = read_configuration( config_file_name )

      ensure_windows_hyperv_is_disable_when_up_or_reload()
      install_specified_plugins( %w( vagrant-vbguest ) )
      install_extra_plugins_from_configuration()
      setup_vagrant_provider_from_configuration()

      @multi_machine = get_multi_machine_properties()
      @single_machine = get_single_machine_properties()

      @multi_machine_name_prefix_map = {}
      @multi_machines_hostname_prefix_map = {}
    end

    def from_machines_ip_addresses()
      return @multi_machine.ip_addresses.select{ | ip | ip }
    end

    def get_machine_ssh_command_extra_args()
      return @single_machine.ssh_command_extra_args.dup
    end

    # TODO: dirty function, referential transparency is violated
    def get_next_machine_name_prefix( index )
      if not is_multi_machine_enabled()
        return 'default' 
      end

      vm_prefix = @multi_machine.vm_prefixes[ index ]

      if ( vm_prefix == nil ) || ( vm_prefix.empty? )
        vm_prefix = 'machine'
      end

      if @multi_machine_name_prefix_map.include?( vm_prefix )
        @multi_machine_name_prefix_map[ vm_prefix ] = @multi_machine_name_prefix_map[ vm_prefix ] + 1
      else
        @multi_machine_name_prefix_map[ vm_prefix ] = 0
      end

      return "#{ vm_prefix }-#{ @multi_machine_name_prefix_map[ vm_prefix ] }"
    end

    # TODO: dirty function, referential transparency is violated
    def get_next_machine_hostname( index )

      if not is_multi_machine_enabled()
        return @single_machine.hostname
      end

      hostname_prefix = @multi_machine.hostname_prefixes[ index ]

      if ( hostname_prefix == nil ) || hostname_prefix.empty?
        hostname_prefix = @single_machine.hostname
      end

      if @multi_machines_hostname_prefix_map.include?( hostname_prefix )
        @multi_machines_hostname_prefix_map[ hostname_prefix ] = @multi_machines_hostname_prefix_map[ hostname_prefix ] + 1
      else
        @multi_machines_hostname_prefix_map[ hostname_prefix ] = 0
      end

      return "#{ hostname_prefix }-#{ @multi_machines_hostname_prefix_map[ hostname_prefix ] }"
    end

    def has_setup_public_network_for_machine( index )
      # vagrant bug : not supported but should work as soon as vagrant has fixed its stuff
      is_single_machine_public_network_enabled = @single_machine.create_public_network && ( not is_multi_machine_enabled() )
      is_multi_machine_public_network_enabled = @multi_machine.create_public_network[ index ]

      return is_single_machine_public_network_enabled || is_multi_machine_public_network_enabled
    end

    def from_machine_forwarded_ports( index )
      return can_setup_forwarded_ports_for_machine( index ) ? single_machine.forwarded_ports.select { | rule | rule } : []
    end

    def from_machine_synced_folders( index )
      if not @single_machine.synced_folders
        return []
      end

      if ( not is_multi_machine_enabled ) || multi_machine_have_shared_synced_folders( index )
        return @single_machine.synced_folders.select { | synced_folder | synced_folder }
      end

      return []
    end

    def is_multi_machine_enabled()
      return @multi_machine.ip_addresses.length() > 1
    end

    def get_machine_cpu_count( index )
      if not is_multi_machine_enabled()
        return @single_machine.cpu
      end

      if @multi_machine.cpus[ index ] && ( @multi_machine.cpus[ index ] > 0 )
        return @multi_machine.cpus[ index ]
      end
    end

    def get_machine_cpu_cap( index )
      if not is_multi_machine_enabled()
        return @single_machine.cpu_cap
      end

      if @multi_machine.cpu_caps[ index ] && ( @multi_machine.cpu_caps[ index ] > 0 )
        return @multi_machine.cpu_caps[ index ]
      end
    end

    def get_machine_memory( index )
      if not is_multi_machine_enabled()
        return @single_machine.memory
      end

      if @multi_machine.memories[ index ] && ( @multi_machine.memories[ index ] > 0 )
        return @multi_machine.memories[ index ]
      end
    end

    def provisioning_properties()
      return Class.new do
        def initialize( configuration )
          @configuration = configuration
        end

        def zoneinfo_region()           @configuration[ 'provisioning' ][ 'zoneinfo_region' ].dup() end;
        def zoneinfo_city()             @configuration[ 'provisioning' ][ 'zoneinfo_city' ].dup() end;
        def keymap()                    @configuration[ 'provisioning' ][ 'keymap' ].dup() end;
        def keymap_variant()            @configuration[ 'provisioning' ][ 'keymap_variant' ].dup() end;
        def docker_volume_auto_extend() @configuration[ 'provisioning' ][ 'docker_volume_auto_extend' ] ? 1 : 0 end;
        def extra_packages()            ( defined? @configuration[ 'provisioning' ][ 'extra_packages' ].join ) ? @configuration[ 'provisioning' ][ 'extra_packages' ].join(' ') : '' end;
        def kv_db_file()                @configuration[ 'provisioning' ][ 'kv_db_file' ].dup() end;
        def kv_db_file_create_link()    @configuration[ 'provisioning' ][ 'kv_db_file_create_link ' ] ? 1 : 0 end;
        def kv_record_separator()       @configuration[ 'provisioning' ][ 'kv_record_separator' ].dup() end;
        def kv_assignment_operator()    @configuration[ 'provisioning' ][ 'kv_assignment_operator' ].dup() end;
        def kv_db_records()             ( defined? @configuration[ 'provisioning' ][ 'kv_db_records' ].join ) ? @configuration[ 'provisioning' ][ 'kv_db_records' ].join( kv_record_separator ) : '' end;
      end.new( @configuration )
    end

    private

    def read_configuration( config_file_name )
      if not FileTest::file?( config_file_name )
        puts "Information, no 'config.yaml' file found. Default value wile be used."
        puts "Consider to create your own config.yaml file from the config.yaml.dist "
        puts "template."

        return YAML.load_file( "#{ config_file_name }.dist" )
      end

      return YAML.load_file( config_file_name )
    end

    def ensure_windows_hyperv_is_disable_when_up_or_reload()
      if( ARGV[ 0 ] == "up" || ARGV[ 0 ] == "reload" )
        if Vagrant::Util::Platform.windows? then
          if not system "powershell -ExecutionPolicy ByPass ./WindowsHyperVDeactivation.ps1"
            abort "Windows hyper-v deactivation has failed. Aborting."
          end
        end
      end
    end

    def install_specified_plugins( plugins )
      plugins_to_install = plugins.select { | plugin | not Vagrant.has_plugin? plugin }

      if not plugins_to_install.empty?
        puts "Installing specified plugins: #{ plugins_to_install.join( ' ' ) }"
        if install_plugin_dependencies( plugins_to_install )
          exec "vagrant #{ ARGV.join( ' ' ) }"
        else
          abort "Installation of one or more specified plugins or their dependencies have failed. Aborting."
        end
      end
    end

    def install_extra_plugins_from_configuration()
      extra_plugins = @configuration[ 'vagrant' ][ 'extra_plugins' ]

      if not extra_plugins
        return
      end

      install_specified_plugins( extra_plugins )
    end

    def setup_vagrant_provider_from_configuration()
      vagrant_provider = @configuration[ 'vagrant' ][ 'default_provider' ]

      if vagrant_provider != "virtualbox"
        abort "Cannot up DockerBox with the #{ vagrant_provider } provider. Only 'virtualbox' provider is supported"
      end

      ENV[ 'VAGRANT_DEFAULT_PROVIDER' ] = vagrant_provider
    end

    def get_multi_machine_properties()
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
      end.new( @configuration )
    end

    def get_single_machine_properties()
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
      end.new( @configuration )
    end

    def can_setup_forwarded_ports_for_machine( index )
      if index > 0
        return false
      end

      return @single_machine.forwarded_ports && @single_machine.forwarded_ports.length() > 0
    end

    def multi_machine_have_shared_synced_folders( index )
      return @multi_machine.shared_synced_folders[ index ]
    end
  end
end