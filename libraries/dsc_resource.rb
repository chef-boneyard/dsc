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

require_relative 'dsc_provider'

class DscResource < Chef::Resource

  provides :dsc_resource, :on_platforms => ["windows"]

  attr_reader :properties

  def initialize(name, run_context)
    super
    @properties = {}
    @resource_name = nil
    @allowed_actions.push(:set)
    @allowed_actions.push(:test)
    @action = :set
    provider(DscProvider)
  end

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

    normalized_property_name = property_name.to_s.to_sym

    if value.nil?
      @properties[normalized_property_name]
    else
      @properties[normalized_property_name] = value
    end
  end
end
