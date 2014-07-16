#
# Author:: Adam Edwards (<adamed@getchef.com>)
#
# Copyright:: 2014, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'dsc_resource_store'

class DscProvider < Chef::Provider
  def initialize(dsc_resource, run_context)
    super(dsc_resource, run_context)
    @dsc_resource = dsc_resource
    @resource_converged = false
    @property_map = {}
    @normalized_properties
    @ps_module = nil
  end

  def action_set
    if ! @resource_converged
      converge_by("DSC Resource type '#{@dsc_resource.resource_name}'") do
        set_configuration
        Chef::Log.info("DSC Resource type '#{@dsc_resource.resource_name}' Configuration completed successfully")
      end
    end
  end

  def load_current_resource
    native_resource = get_native_dsc_resource
    @ps_module = native_resource['Module']
    native_resource['Properties'].each { |property_data| @property_map.store(property_data['Name'].downcase, property_data) }

    @normalized_properties = get_normalized_properties!
    @resource_converged = ! run_configuration(:test)
  end

  def whyrun_supported?
    true
  end

  protected

  def get_normalized_properties!
    normalized_properties = {}
    @dsc_resource.properties.keys.each do | property_name |
      property_value = @dsc_resource.properties[property_name]
      add_normalized_property!(normalized_properties, property_name, property_value)
    end

    normalized_properties
  end

  def get_native_dsc_resource
    DscResourceStore.get_resource(@dsc_resource.resource_name)
  end

  def validate_property!(property_key)
    @property_map.fetch(property_key)
  end

  def add_normalized_property!(normalized_properties, property_name, property_value)
    key = property_name.to_s.downcase
    validate_property!(key)
    normalized_properties.store(key.to_sym, property_value)
  end

  def generate_configuration(config_directory)
    code = get_configuration_code
    Chef::Log.debug("DSC code:\n '#{code}'")
    run_powershell(config_directory, code)
  end

  def get_configuration_code
    <<-EOH
configuration 'chef_dsc'
{
#{module_code}
#{resource_code}
}
chef_dsc
EOH
  end

  def module_code
    module_name = @ps_module ? @ps_module['Name'] : nil
    module_name.nil? ? nil : "import-dscresource -module #{module_name}"
  end

  def resource_code
    <<-EOH
    #{@dsc_resource.resource_name} 'chef_dsc'
    {
#{property_code}
    }
EOH
  end

  def property_code
    properties = @normalized_properties.map { |name, value| 
      value_code = value
      value_code = "'#{value_code}'" if ! value_code.kind_of? Numeric
      "        #{name} = #{value_code}"
    }
    
    properties.join("\n")
  end

  def run_powershell(config_directory, code) 
    cmdlet = PowershellCmdlet.new("#{code}")
    cmdlet.run
  end
  
  def set_configuration
    run_configuration :set
  end

  def run_configuration(command)
    case command
    when :set
      command_code = 'start-dscconfiguration chef_dsc -wait -force'
    when :test
      command_code = 'start-dscconfiguration chef_dsc -wait -whatif; if (! $?) { exit 1 }'
    else
      raise ArgumentError, "#{command.to_s} is not a valid configuration command"
    end
    
    config_directory = Dir.mktmpdir("dsc-script")
    generate_configuration config_directory

    begin
      status = run_powershell(config_directory, command_code)
      if command == :test
        configuration_update_required?(status.return_value)
      else
        true
      end
    ensure
      FileUtils.rm_rf(config_directory)
    end
  end

  def configuration_update_required?(what_if_output)
    parse_what_if_output(what_if_output)
  end

  def parse_what_if_output(what_if_output)

    # What-if output for start-dscconfiguration contains lines that look like one of the following:
    #
    # What if: [SEA-ADAMED1]: LCM:  [ Start  Set      ]  [[Group]chef_dsc]
    # What if: [SEA-ADAMED1]:                            [[Group]chef_dsc] Performing the operation "Add" on target "Group: demo1"
    # 
    # The second line lacking the 'LCM:' is what happens if there is a change require to make the system consistent with the resource.
    # Such a line without LCM is only present if an update to the system is required. Therefore, we test each line below
    # to see if it is missing the LCM, and declare that an update is needed if so.
    has_change_line = false
    
    what_if_output.lines.each do |line|
      if (line =~ /.+\:\s+\[\S*\]\:\s+LCM\:/).nil?
        has_change_line = true
        break
      end
    end
    
    has_change_line
  end
end
