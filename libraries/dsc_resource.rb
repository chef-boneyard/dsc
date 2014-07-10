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

require_relative 'dsc_resource_state.rb'
require_relative 'config_script'

class DscResource < Chef::Resource

  attr_reader :resource_state

  protected
  
  def initialize(name, run_context)
    super(name, run_context)
    @dsc_native_name = dsc_native_name.downcase.to_sym
    @resource_state = DscResourceState.new(@dsc_native_name)
    @resource_name = "dsc_#{@dsc_native_name}".to_sym
    @allowed_actions.push(:set)
    @allowed_actions.push(:test)
    @action = :set
    provider(ConfigScript)
  end

  def property(property_name, value=nil, validate=false)
    if value.nil?
      @resource_state.get_property(property_name)
    else
      @resource_state.set_property(property_name, value)
    end
  end
end
