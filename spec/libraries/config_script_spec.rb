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
require_relative '../../libraries/config_script.rb'

require 'chef'

describe ConfigScript do
  before(:all) do
    ohai_reader = Ohai::System.new
    ohai_reader.all_plugins("platform")

    new_node = Chef::Node.new
    new_node.consume_external_attrs(ohai_reader.data,{})

    events = Chef::EventDispatch::Dispatcher.new

    @run_context = Chef::RunContext.new(new_node, {}, events)
  end

  before(:each) do
  end

  after(:each) do
  end
  
  it "should create a new ConfigScript class" do
    new_resource_class = DscResourceBuilder.create_resource_classes('WindowsFeature')[0]
    new_resource = new_resource_class.new('myfeature', @run_context)
    config_script = ConfigScript.new(new_resource, @run_context)
    expect( config_script.nil? ).to eq(false)
  end
end
