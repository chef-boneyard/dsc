#
# Cookbook Name:: dsc
# Recipe:: telnet
#
# Copyright 2013, Opscode, Inc.
#
# All rights reserved - Do Not Redistribute
#

dsc_configuration_script "feature" do 
  param :feature, "Telnet-Client"
  code <<-EOH
    WindowsFeature NewFeature
    {
        Ensure = "Present"
        Name = $feature
    }
EOH
end
