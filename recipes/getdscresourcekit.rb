#
# Author:: Adam Edwards (<adamed@getchef.com>)
# Author:: Julian Dunn (<jdunn@getchef.com>)
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

remote_file "#{Chef::Config[:file_cache_path]}\\DSC Resource Kit 03282014.zip" do
  source 'http://gallery.technet.microsoft.com/scriptcenter/DSC-Resource-Kit-All-c449312d/file/116327/1/DSC%20Resource%20Kit%20Wave%204%2006052014.zip'
end

dsc_resource 'get-dsc-resource-kit' do
  resource_name :archive
  property :ensure, 'Present'
  property :path, "#{Chef::Config[:file_cache_path]}\\DSC Resource Kit 03282014.zip"
  property :destination, "#{ENV['PROGRAMW6432']}\\WindowsPowerShell\\Modules"
end

=begin
x_dsc_archive 'get-dsc-resource-kit' do
  property :ensure, 'Present'
  property :path, "#{Chef::Config[:file_cache_path]}\\DSC Resource Kit 03282014.zip"
  property :destination, "#{ENV['PROGRAMW6432']}\\WindowsPowerShell\\Modules"
end
=end
