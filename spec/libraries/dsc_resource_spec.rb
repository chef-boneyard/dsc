#
# Author:: Adam Edwards (<adamed@chef.io>)
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

require_relative '../spec_helper.rb'
require_relative '../../libraries/dsc_resource.rb'

describe DscResource do
  before(:all) do
    ohai_reader = Ohai::System.new
    ohai_reader.all_plugins('platform')

    new_node = Chef::Node.new
    new_node.consume_external_attrs(ohai_reader.data, {})

    events = Chef::EventDispatch::Dispatcher.new

    @run_context = Chef::RunContext.new(new_node, {}, events)
  end

  before(:each) do
    # Keep test output free of warnings from deprecated attributes
    allow(Chef::Log).to receive(:warn)
  end

  let(:new_resource) do
    DscResource.new('testclass', @run_context)
  end

  it 'should be able to create a new instance of WindowsFeature using the deprecated resource_name attribute' do
    new_resource.resource_name :windowsfeature
    windows_feature = new_resource
    expect(windows_feature.property(:name)).to eq(nil)
    expect(windows_feature.name).to eq('testclass')
    expect(windows_feature.class.to_s).to eq('DscResource')
    expect(windows_feature.resource).to eq('windowsfeature'.downcase.to_sym)
    expect(windows_feature.resource_name).to eq(:dsc_resource)

    expect { windows_feature.property(:dsc_not_a_property) }.not_to raise_error
    expect { windows_feature.property(:dsc_not_a_property, 'notthere') }.not_to raise_error

    expect { windows_feature.run_action(:set) }.to raise_error KeyError
  end

  it 'should be able to create a new instance of WindowsFeature using the resource attribute' do
    new_resource.resource :windowsfeature
    windows_feature = new_resource
    expect(windows_feature.property(:name)).to eq(nil)
    expect(windows_feature.name).to eq('testclass')
    expect(windows_feature.class.to_s).to eq('DscResource')
    expect(windows_feature.resource).to eq('windowsfeature'.downcase.to_sym)
    expect(windows_feature.resource_name).to eq(:dsc_resource)

    expect { windows_feature.property(:dsc_not_a_property) }.not_to raise_error
    expect { windows_feature.property(:dsc_not_a_property, 'notthere') }.not_to raise_error

    expect { windows_feature.run_action(:set) }.to raise_error KeyError
  end

  it 'should be able to execute the set action of an instance of Environment' do
    new_resource.resource_name :environment
    variable_name = "dsc_test_#{Time.now.nsec}"
    variable_value = Time.now.to_s
    new_resource.property :name, variable_name
    new_resource.property :value, variable_value

    expect(new_resource.resource).to eq('environment'.downcase.to_sym)
    expect(new_resource.resource_name).to eq(:dsc_resource)
    expect { new_resource.run_action(:set) }.not_to raise_error
  end

  it 'should raise a runtime exception if a non-existent DSC resource is specified for the resource_name attribute' do
    new_resource.resource_name :idontexist
    expect { new_resource.run_action(:set) }.to raise_error
  end

  #   it "should be able to create new classes and instances for all resources" do
  #     classes = DscResourceBuilder.create_resource_classes
  #
  #     classes.each do | klass |
  #       new_object = klass.new('testclass', @run_context)
  #
  #       class_name = new_object.dsc_native_name
  #       expect(class_name.nil?).to eq(false)
  #       expect(class_name.length).to be >= 1
  #       expect(new_object.resource_name).to eq("dsc_#{class_name}".downcase.to_sym)
  #     end
  #   end

  it 'should have :set and :test as allowed actions' do
    expect(new_resource.allowed_actions.include?(:set)).to eq(true)
    expect(new_resource.allowed_actions.include?(:test)).to eq(true)
  end

  it 'should have a default action of :set' do
    expect(new_resource.action).to eq(:set)
  end

  it 'should have a provider of Chef::Provider::DscProvider' do
    expect(new_resource.provider).to eq(DscProvider)
  end

  it 'should be able to set and return a property of WindowsFeature' do
    windows_feature = new_resource
    expect(windows_feature.property(:name)).to eql(nil)
    windows_feature.property(:name, 'myname')
    expect(windows_feature.property(:name)).to eq('myname')
    expect(windows_feature.property(:includeallsubfeature)).to eq(nil)
    windows_feature.property(:includeallsubfeature, true)
    expect(windows_feature.property(:includeallsubfeature)).to eq(true)
  end

  it 'should be able to coerce a boolean property of Environment during converge' do
    new_resource.resource_name(:environment)
    new_resource.property(:value, 'mypath')
    new_resource.property(:name, 'c:\fun.txt')
    new_resource.property(:path, true)
    expect(new_resource.property(:path)).to eq(true)
    expect { new_resource.run_action(:test) }.not_to raise_error
  end
end
