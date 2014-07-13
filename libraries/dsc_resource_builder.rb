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

require_relative 'dsc_resource_store'
require_relative 'dsc_resource'

class DscResourceBuilder
  @@resource_names = nil
  @@resource_classes = nil

  DSC_LEXICAL_PREFIX = 'dsc_'

  def self.create_resource_classes(resource_filter = nil)

    @@resource_names ||= DscResourceStore.get_resource_names
    @@resource_classes ||= {}
    
    result = []
    @@resource_names.each do | resource_name |
      resource_class = @@resource_classes[resource_name]

      if resource_filter && !resource_filter.include?(resource_name)
        next
      end

      if resource_class.nil? && (resource_filter.nil? || resource_filter.include?(resource_name))
        resource = DscResourceStore.get_resource(resource_name)
        resource_class = new_class(DscResource, resource_name, resource['Properties'])
        @@resource_classes[resource_name] = resource_class
      end

      result.push(resource_class) if resource_class
    end
    result
  end

  def self.new_class(parent, name, properties)
    resource_class = Class.new(parent)
    parent.const_set(name, resource_class)
    result_class = parent.const_get(name)
    prop_block = Proc.new { properties }
    name_block = Proc.new { name }
    resource_class.class_eval {  define_method(:class_properties, prop_block) }
    resource_class.class_eval {  define_method(:dsc_native_name, name_block) }

    if parent.ancestors.include?(Chef::Resource)
      resource_class.class_eval do
        dsc_class_symbol = "#{DSC_LEXICAL_PREFIX}#{name}".downcase.to_sym
        provides( dsc_class_symbol, :on_platforms => ["windows"] ) 
      end
    end

#    create_methods(resource_class, properties)

    resource_class
  end
  
  def self.create_methods(resource_class, properties)
    properties.each do | property |
      new_property_method(resource_class, property['Name'].downcase)
    end
  end
  
  def self.new_property_method(resource_class, name)
    method_prefix = ''

    if resource_class.method_defined?(name.to_sym)
      method_prefix = DSC_LEXICAL_PREFIX
    else
      begin
        test_class = Class.new
        result = test_class.class_eval("begin\n#{name}='test'\ntrue\nrescue\nfalse\nend")
      rescue Exception => e
        method_prefix = DSC_LEXICAL_PREFIX
      end
    end

    new_method(resource_class, method_prefix, name)
  end

  def self.new_method(resource_class, prefix, name)
    method_name = "#{prefix}#{name}".to_sym
    Chef::Log.debug("Defining DSC property method #{method_name.to_s}")
    resource_class.class_eval do 
      define_method(method_name) do | *args |
        args2 = [name]
        args2.concat(args) if args.length > 0
        property(*args2)
      end
    end
  end
end
