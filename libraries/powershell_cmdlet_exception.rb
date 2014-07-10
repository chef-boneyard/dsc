# Author:: Adam Edwards (<adamed@getchef.com>)
# Cookbook Name:: dsc Resource:: configuration
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

class PowershellCmdletException < Exception

  def initialize(cmdlet_result, message=nil)
    super(message)
    @cmdlet_result = cmdlet_result
  end
  
  attr_reader :cmdlet_result
  
end

