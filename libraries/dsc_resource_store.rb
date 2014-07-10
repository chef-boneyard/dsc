#
# Author:: Adam Edwards (<adamed@getchef.com>)
#
# Copyright:: 2014, Opscode, Inc.
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

require_relative 'powershell_cmdlet.rb'

class DscResourceStore

  @@resources = nil
  @@resource_names = nil
  @@resources_json = nil
  @@resource_data = nil
  
  def self.get_resources
    if @@resources_json.nil?
      @@resources_json = query_resources
      @@resources = JSON.parse(@@resources_json)
    end

    JSON.parse(@@resources_json)
  end

  def self.get_resource(resource_name)
    current_resource = find_resource(resource_name)

    if current_resource.nil?
      current_resource = add_resource(resource_name)
    end

    current_resource
  end
  
  def self.get_resource_data
    get_resources
    
    if @@resource_data.nil?
      @@resource_data = query_resource_data(@@resource_names)
    else
      @@resource_data
    end
  end

  def self.get_resource_names
    get_resources

    @@resource_names = @@resources.collect { |resource| resource['Name'] }
    @@resource_names.freeze
    @@resource_names
  end

  private

  def self.query_resources
    get_resources_cmd = PowershellCmdlet.new('$progresspreference = \"silentlycontinue\"; get-dscresource', :json)

    result = get_resources_cmd.run

    result.return_value
  end

  def self.query_resource_data(resource_names)
    resource_table = Hash.new

    resource_names.each do | resource_name |
      add_resource(resource_name)
    end

    resource_table
  end

  def self.query_resource(resource_name, expanded_property=nil)
    property_filter = ""

    if expanded_property
      property_filter = " | select-object -expandproperty #{expanded_property}"
    end
    
    get_resources_data_cmd = PowershellCmdlet.new('$progresspreference = \"silentlycontinue\";' + " get-dscresource #{resource_name} #{property_filter}", :object)

    result = get_resources_data_cmd.run

    result.return_value
  end

  def self.find_resource(resource_name)
    if @@resource_data && @@resource_data.has_key?(resource_name.downcase)
      @@resource_data[resource_name.downcase]
    else
      nil
    end    
  end

  def self.add_resource(resource_name)
    if find_resource(resource_name)
      raise RuntimeError, 'Resource #{resource_name} already exists'
    end

    @@resource_data = Hash.new if @@resource_data.nil?

    Chef::Log.info("Getting PowerShell DSC resource '#{resource_name}'")
    @@resource_data[resource_name.downcase] = query_resource(resource_name)
    @@resource_data[resource_name.downcase]['Properties'] = query_resource(resource_name, 'Properties')

    @@resource_data[resource_name.downcase]
  end
end


