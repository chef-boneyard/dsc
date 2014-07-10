#
# Cookbook Name:: dsc
# Recipe:: default
# Author:: Julian C. Dunn (<jdunn@opscode.com>)
#
# Copyright (C) 2013 Opscode, Inc.
# 
# MICROSOFT CONFIDENTIAL
# NDA MATERIAL FOR WMF 4.0 NDA Preview Partners ONLY
# DO NOT DISTRIBUTE
#

windows_batch 'uninstall WMF 4.0 preview' do
  code "WUSA /UNINSTALL /KB:2819745 /QUIET /NORESTART"
  action :run
  returns [0, 3010] # ERROR_SUCCESS_REBOOT_REQUIRED
  only_if do
    registry_data_exists?('HKLM\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine', { :name => 'PowerShellVersion', :type => :string, :data => '4.0' }, :machine)
  end
  notifies :request, 'windows_reboot[reboot-after-wmf-uninstall]'
end

windows_reboot 'reboot-after-wmf-uninstall' do
  reason 'Reboot after uninstalling Windows Management Framework 4.0 patch'
  action :nothing
end
