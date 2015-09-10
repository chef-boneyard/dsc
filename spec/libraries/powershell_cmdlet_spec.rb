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

describe PowershellCmdlet do
  let(:cmd_output_format) { :text }
  let(:simple_cmdlet) { PowershellCmdlet.new('get-childitem', cmd_output_format) }
  let(:invalid_cmdlet) { PowershellCmdlet.new('get-idontexist', cmd_output_format) }
  let(:cmdlet_requires_switch_or_argument) { PowershellCmdlet.new('get-item', cmd_output_format) }
  let(:etc_directory) { "#{ENV['systemroot']}\\system32\\drivers\\etc" }
  let(:architecture_cmdlet) { PowershellCmdlet.new('$env:PROCESSOR_ARCHITECTURE') }
  it 'executes a simple process' do
    result = simple_cmdlet.run
    expect(result.succeeded?).to eq(true)
  end

  it 'returns a PowershellCmdletException exception if the command cannot be executed' do
    exception_occurred = nil

    begin
      invalid_cmdlet.run
      exception_occurred = false
    rescue PowershellCmdletException => e
      exception_occurred = true
      expect(e.cmdlet_result.succeeded?).to eq(false)
    end

    expect(exception_occurred).to eq(true)
  end

  it 'executes a 64-bit command on a 64-bit OS, 32-bit otherwise' do
    os_arch = ENV['PROCESSOR_ARCHITEW6432']
    os_arch = ENV['PROCESSOR_ARCHITECTURE'] if os_arch.nil?

    result = architecture_cmdlet.run
    execution_arch = result.return_value
    execution_arch.strip!
    expect(execution_arch).to eq(os_arch)
  end

  it 'passes command line switches to the command' do
    result = cmdlet_requires_switch_or_argument.run(path: '.')
    expect(result.succeeded?).to eq(true)
  end

  it 'passes command line arguments to the command' do
    result = cmdlet_requires_switch_or_argument.run({}, {}, '.')
    expect(result.succeeded?).to eq(true)
  end

  it 'passes command line arguments and switches to the command' do
    result = cmdlet_requires_switch_or_argument.run({ path: etc_directory }, {}, ' | select-object -property fullname | format-table -hidetableheaders')
    expect(result.succeeded?).to eq(true)
    returned_directory = result.return_value
    returned_directory.strip!
    expect(returned_directory).to eq(etc_directory)
  end

  it 'passes execution options to the command' do
    result = cmdlet_requires_switch_or_argument.run({}, { cwd: etc_directory }, '. | select-object -property fullname | format-table -hidetableheaders')
    expect(result.succeeded?).to eq(true)
    returned_directory = result.return_value
    returned_directory.strip!
    expect(returned_directory).to eq(etc_directory)
  end

  context 'when returning json' do
    let(:cmd_output_format) { :json }
    it 'returns json format data' do
      result = cmdlet_requires_switch_or_argument.run({}, {}, '.')
      expect(result.succeeded?).to eq(true)
      expect(-> { JSON.parse(result.return_value) }).not_to raise_error
    end
  end

  context 'when returning Ruby objects' do
    let(:cmd_output_format) { :object }
    it 'returns object format data' do
      result = cmdlet_requires_switch_or_argument.run({}, { cwd: etc_directory }, '.')
      expect(result.succeeded?).to eq(true)
      data = result.return_value
      expect(data['FullName']).to eq(etc_directory)
    end
  end

  context 'when constructor is given invalid arguments' do
    let(:cmd_output_format) { :invalid }
    it 'throws an exception if an invalid format is passed to the constructor' do
      expect(-> { simple_cmdlet }).to raise_error
    end
  end
end
