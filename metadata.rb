name             'dsc'
maintainer       'Chef Software, Inc'
maintainer_email 'cookbooks@chef.io'
license          'Apache 2.0'
description      'Experimental primitives to integrate with Microsoft Desired State Configuration'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports 'windows'

source_url 'https://github.com/chef-cookbooks/dsc' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/dsc/issues' if respond_to?(:issues_url)
