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
require_relative '../../libraries/dsc_resource.rb'

describe DscResource do
  before(:all) do
    ohai_reader = Ohai::System.new
    ohai_reader.all_plugins("platform")

    new_node = Chef::Node.new
    new_node.consume_external_attrs(ohai_reader.data,{})

    events = Chef::EventDispatch::Dispatcher.new

    @run_context = Chef::RunContext.new(new_node, {}, events)
  end

  let(:new_resource) do
    DscResource.new('testclass', @run_context)
  end

  let(:dsc_resource_name) { 'WindowsFeature' }
  it "should be able to create a new instance of WindowsFeature" do
    new_resource.resource_name :windowsfeature
    windows_feature = new_resource
    expect(windows_feature.property(:name)).to eq(nil)
    expect(windows_feature.name).to eq('testclass')
    expect(windows_feature.class.to_s).to eq('DscResource')
    expect(windows_feature.resource_name).to eq("windowsfeature".downcase.to_sym)

    expect { windows_feature.property(:dsc_not_a_property) }.not_to raise_error
    expect { windows_feature.property(:dsc_not_a_property, 'notthere') }.not_to raise_error

    expect { windows_feature.run_action(:set) }.to raise_error KeyError
  end
=begin
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
=end
=begin
  it "should remap the name of a DSC resource property that is a Ruby keyword with a dsc_prefix when it defines the method for it" do
    windows_feature = new_resource
    expect(windows_feature.dsc_ensure).to eq(nil)
    windows_feature.dsc_ensure('Present')
    expect(windows_feature.dsc_ensure).to eq('Present')

    expect { windows_feature.ensure }.to raise_error NoMethodError
  end
=end

  it "should have :set and :test as allowed actions" do
    expect(new_resource.allowed_actions.include?(:set)).to eq(true)
    expect(new_resource.allowed_actions.include?(:test)).to eq(true)
  end

  it "should have a default action of :set" do
    expect(new_resource.action).to eq(:set)
  end

  it "should have a provider of Chef::Provider::DscProvider" do
    expect(new_resource.provider).to eq(DscProvider)
  end

  it "should be able to set and return a property of WindowsFeature" do
    windows_feature = new_resource
    expect(windows_feature.property(:name)).to eql(nil)
    windows_feature.property(:name, 'myname')
    expect(windows_feature.property(:name)).to eq('myname')
    expect(windows_feature.property(:includeallsubfeature)).to eq(nil)
    windows_feature.property(:includeallsubfeature, '$true')
    expect(windows_feature.property(:includeallsubfeature)).to eq('$true')
  end

end


