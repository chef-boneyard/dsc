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

require_relative '../spec_helper.rb'
require_relative '../../libraries/dsc_resource_builder.rb'

describe DscResourceBuilder do
  let(:builder) {DscResourceBuilder.new}
  
  before(:each) do
    class Dsc
      class TestParent
      end
    end
  end

  after(:each) do
    fun = Object.send(:const_get, 'Dsc')
    Object.send(:remove_const, 'Dsc'.to_sym)
  end
  
  it "should create a new class" do
    class Dsc::TestParent
    end
    resource_class = DscResourceBuilder.new_class(Dsc::TestParent, 'TestClass', []) 
    expect(resource_class).to eq(Dsc::TestParent::TestClass)
    expect(resource_class.superclass).to eq(Dsc::TestParent)
  end
  
  it "should create a new class with specific methods" do
    class Dsc::TestParent2
      def property(name, value=nil)
        'hello_me'
      end
    end
    resource_class = DscResourceBuilder.new_class(Dsc::TestParent2, 'TestClass', []) 

    DscResourceBuilder.new_property_method(resource_class, 'hello_me')
    fun = resource_class.new
    expect(fun.hello_me).to eq("hello_me")
  end

  it "should create a new class with property methods" do
    class Dsc::TestParent3
      def initialize
        @state = {}
      end
      def property(name, value=nil)
        value.nil? ? @state[name] : @state[name] = value
      end
    end
    resource_class = DscResourceBuilder.new_class(Dsc::TestParent3, 'TestClass', []) 

    DscResourceBuilder.create_methods(resource_class, [{'Name' => 'prop1'}, {'Name' => 'prop2'}])

    fun = resource_class.new

    fun.prop1('first')
    fun.prop2('second')

    expect(fun.prop1).to eq('first')
    expect(fun.prop2).to eq('second')
  end

  let(:new_resource) do
    resource_class = DscResourceBuilder.create_resource_classes([dsc_resource_name])
    resource_instance = resource_class[0].new('testclass', @run_context)
  end

  let(:dsc_resource_name) { 'WindowsFeature' }
  it "should be able to create a new instance of WindowsFeature" do
    windows_feature = new_resource
    expect(windows_feature.dsc_name).to eq(nil)
    expect(windows_feature.name).to eq('testclass')
    expect(windows_feature.class.to_s).to eq('DscResource::WindowsFeature')
    expect(windows_feature.resource_name).to eq("dsc_windowsfeature".downcase.to_sym)

    expect { windows_feature.dsc_not_a_property }.to raise_error NoMethodError
  end

  it "should be able to create new classes and instances for all resources" do
    classes = DscResourceBuilder.create_resource_classes

    classes.each do | klass |
      new_object = klass.new('testclass', @run_context)
      
      class_name = new_object.dsc_native_name
      expect(class_name.nil?).to eq(false)
      expect(class_name.length).to be >= 1
      expect(new_object.resource_name).to eq("dsc_#{class_name}".downcase.to_sym)
    end
  end

  it "should remap the name of a DSC resource property that is a Ruby keyword with a dsc_prefix when it defines the method for it" do
    windows_feature = new_resource
    expect(windows_feature.dsc_ensure).to eq(nil)
    windows_feature.dsc_ensure('Present')
    expect(windows_feature.dsc_ensure).to eq('Present')

    expect { windows_feature.ensure }.to raise_error NoMethodError
  end

  it "should have :set and :test as allowed actions" do
    expect(new_resource.allowed_actions.include?(:set)).to eq(true)
    expect(new_resource.allowed_actions.include?(:test)).to eq(true)
  end

  it "should have a default action of :set" do
    expect(new_resource.action).to eq(:set)
  end

  it "should have a provider of Chef::Provider::ConfigScript" do
    expect(new_resource.provider).to eq(ConfigScript)
  end

  it "should be able to set and return a property of WindowsFeature" do
    windows_feature = new_resource
    expect(windows_feature.dsc_name).to eql(nil)
    windows_feature.dsc_name('myname')
    expect(windows_feature.dsc_name).to eq('myname')
    expect(windows_feature.includeallsubfeature).to eq(nil)
    windows_feature.includeallsubfeature('$true')
    expect(windows_feature.includeallsubfeature).to eq('$true')
  end

  it "should be able to create only the classes for specific dsc resources" do
    classes_filter = ['WindowsFeature', 'Group']
    classes = DscResourceBuilder.create_resource_classes(classes_filter)

    expect(classes.length).to eq(classes_filter.length)

    classes.each do | klass |
      new_object = klass.new('testclass', @run_context)

      class_name = new_object.dsc_native_name
      expect(class_name.nil?).to eq(false)
      expect(class_name.length).to be >= 1
      expect(new_object.resource_name).to eq("dsc_#{class_name}".downcase.to_sym)
    end
  end
  

  it "should be able to create only the classes for specific dsc resources" do
    classes_filter = ['WindowsFeature', 'Group']
    classes = DscResourceBuilder.create_resource_classes(classes_filter)

    expect(classes.length).to eq(classes_filter.length)

    classes.each do | klass |
      new_object = klass.new('testclass', @run_context)
      class_name = new_object.dsc_native_name
      expect(class_name.nil?).to eq(false)
      expect(class_name.length).to be >= 1
      expect(new_object.resource_name).to eq("dsc_#{class_name}".downcase.to_sym)
    end
  end


end

