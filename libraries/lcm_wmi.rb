module Windows
  module DSC
    class ConfigurationStatus
      attr_reader :in_desired_state

      def initialize(in_desired_state)
        @in_desired_state
      end
    end

    class LocalConfigurationManager

      def send_configuration(configuration)
        r = lcm.SendConfiguration(configuration.bytes)
        raise "SendConfiguration failed with code #{r}" unless r == 0
      end

      def test_configuration
        # it's not clear why I can't send a configuration here
        r = lcm.TestConfiguration(nil, false, [nil])
        raise "TestConfiguration failed with code #{r}" unless r == 0

        ConfigurationStatus.new(WIN32OLE::ARGV[1])
      end

      def apply_configuration
        r = lcm.ApplyConfiguration()
        raise "ApplyConfiguration failed with code #{r}" unless r == 0
      end

      def lcm
        @lcm ||= WIN32OLE.connect(
          "winmgmts://./root/Microsoft/Windows/DesiredStateConfiguration:MSFT_DSCLocalConfigurationManager")
      end

    end
  end
end
