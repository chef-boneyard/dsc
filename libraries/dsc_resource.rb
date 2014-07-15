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
require_relative 'dsc_provider'

class DscResource < Chef::Resource

  attr_reader :resource_state

  protected
  
  def initialize(name, run_context)
    super(name, run_context)
    if respond_to?(:dsc_native_name)
      @dsc_native_name = dsc_native_name.downcase.to_sym
      @resource_name = @dsc_native_name
      @property_map = {}
      class_properties.each { |property_data| @property_map.store(property_data['Name'].downcase, property_data) }
      @resource_state = DscResourceState.new(@dsc_native_name)
      @resource_name = "dsc_#{@dsc_native_name}".to_sym
    else
      @resource_state = DscResourceState.new(name)
      @resource_name = name
    end
    @allowed_actions.push(:set)
    @allowed_actions.push(:test)
    @action = :set
    provider(DscProvider)
  end

  def method_missing(m)
    if m != :dsc_native_name
      raise MethodMissing, m.to_s
    end
    @resource_name
  end

  public

  def resource_name(value=nil)
    if value
      @resource_name = value
    else
      @resource_name
    end
  end

  def property(property_name, value=nil, validate=false)
    if not property_name.is_a?(Symbol)
      raise TypeError, "A property name of type Symbol must be specified, '#{property_name.to_s}' of type #{property_name.class.to_s} was given"
    end

#    native_property_name = @property_map.fetch(property_name.to_s.downcase)['Name']
    if value.nil?
      @resource_state.get_property(property_name)
    else
      @resource_state.set_property(property_name, value)
    end
  end
end
