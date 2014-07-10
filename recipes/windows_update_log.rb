#
# Cookbook Name:: dsc
# Recipe:: windows_update_log
#
# Copyright 2013, Opscode, Inc.
#
# All rights reserved - Do Not Redistribute
#

log_directory = "#{ENV['SystemDrive']}/log-archive"

directory log_directory do
end

service "wuauserv" do
  action :stop
end

dsc_configuration_script "windowsupdatelog" do 
  param :sourcelocation, "#{ENV['SystemRoot']}/windowsupdate.log"
  param :destinationlocation, log_directory
  code <<-EOH
        File LogFile
        {
            SourcePath = $sourceLocation
            DestinationPath = $destinationLocation
            Ensure = "Present" # Absent is the alternative
        }
   EOH
end







service "wuauserv" do
#  action :start
  action :nothing
end

