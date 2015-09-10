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

require 'json'
require_relative '../spec_helper.rb'
require_relative '../../libraries/dsc_resource_store.rb'

describe DscResourceStore do
  it 'should get resource names on the first call' do
    names = DscResourceStore.get_resource_names
    expect(names.frozen?).to eq(true)
    expect(names.length).to be > 0
  end

  it 'should get the same resource names on the first and subsequent calls' do
    names1 = DscResourceStore.get_resource_names
    names2 = DscResourceStore.get_resource_names

    expect(names1).to eq(names2)

    expect(names1.frozen?).to eq(true)
    expect(names2.frozen?).to eq(true)
  end

  it 'should get WindowsFeature' do
    feature = DscResourceStore.get_resource('WindowsFeature')
    expect(feature.nil?).to eq(false)
  end

  it "should get WindowsFeature when a lowercase version of the name 'windowsfeature' is used" do
    feature = DscResourceStore.get_resource('windowsfeature')
    expect(feature.nil?).to eq(false)
  end

  it 'should get two features successfully' do
    file_feature = DscResourceStore.get_resource('file')
    group_feature = DscResourceStore.get_resource('group')

    expect(file_feature.nil?).to eq(false)
    expect(group_feature.nil?).to eq(false)
  end
end
