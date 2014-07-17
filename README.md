dsc Cookbook
===============

This cookbook demonstrates prototype functionality to expose PowerShell Desired State
Configuration (DSC) resources as Chef resources on the Microsoft Windows
operating system. **It requires PowerShell 4.0 or later**
which is available as part the Windows Management Foundation 4.0 components of Windows.

This library is distributed as a Chef cookbook, use knife to upload it to your
Chef server for testing.

## Installation

To use this cookbook with knife, clone it into a directory in your
cookbook path:

    git clone git@github.com:opscode/dsc
    
## Usage

Upload the cookbook to your Chef server to use it.

### Recipes 

The cookbook contains the following recipes, still being updated

* getdsc: Will download and install DSC Resource kit powershell modules using DSC
* dsc_demo: Creates a security group with one member using DSC

### Resources

All DSC resources on a system that are returned by the command below on that
system will be visible as Chef resources on that system:

    get-dscresource
 
As an example, consider the following DSC `Archive` resource returned from
`get-dscresource`:

    > Get-DscResource archive
    ImplementedAs Name     Module                      Properties
    ------------- ----     ------                      ----------
    PowerShell    Archive  PSDesiredStateConfiguration {Destination, Path, Checksum, DependsOn...}

That `Archive` resource itself contains the following *properties* which can
also be obtained via the `get-dscresource` command:

    > Get-DscResource archive | Select-Object -ExpandProperty Properties

```
    Name        PropertyType IsMandatory Values
    ----        ------------ ----------- ------
    Destination [string]     True        {}
    Path        [string]     True        {}
    Checksum    [string]     False       {CreatedDate, ModifiedDate,...
    DependsOn   [string[]]   False       {}
    Ensure      [string]     False       {Absent, Present}
    Force       [bool]       False       {}
    Validate    [bool]       False       {}
```

If you depend on this cookbook in your own cookbook, you can then write a recipe
that includes the following `dsc_archive` Chef resource, which is actually
just the DSC `Archive` resource exposed in Chef's Domain Specific Language
(DSL) like every other resource in Chef:

```ruby
    dsc_resource 'get-dsc-resource-kit' do
      resource_name :archive
      property :ensure, 'Present'
      property :path, "#{ENV['USERPROFILE']}/Downloads/DSC Resource Kit 03282014.zip"
      property :destination, "#{ENV['PROGRAMW6432']}/WindowsPowerShell/Modules"
    end
```

The example above translates DSC's `Archive` to the `dsc_archive` Chef
resource in the recipe, and the *properties* in the DSC resource are translated
into valid *attributes* of the `dsc_archive` resource. From a DSC standpoint,
the Chef fragment above is analogous to the DSC fragment below:

    configuration 'InstallDSCReskit'
    {
        Archive 'DSCReskitFromModules'
        {
            Ensure = 'Present'
            Path = "$env:USERPROFILE/Downloads/DSC Resource Kit 03282014.zip"
            Destination = "$env:PROGRAMW6432/WindowsPowerShell/Modules"
        }
    }

More details on the correspondence between usage of a DSC resource within the
PowerShell configuration DSL and the use of that same resource from within
Chef's DSL is given below.

### Mapping PowerShell DSC resources to Chef resources

If you've used MSDN documentation or the `get-dscresource` cmdlet to discover
DSC resources and their semantics / usage, you can use the following simple
rules to take the knowledge of those DSC resources and express them in Chef
recipes as Chef resources:

1. To use a DSC resource in Chef, use the `dsc_resource` resource in your recipe
2. Set the `resource_name` attribute to the name of the resource as a symbol, i.e. `WindowsFeature` in DSC becomes
`:windowsfeature`.
3. For each property in the DSC resource for which you want to declare a desired value, use the syntax

```ruby
   property :property_name, value
```

That's it -- note that case *does not* matter for any of the symbols given above, which is also true of names expressed in the
DSC DSL.

For example, we can annotate the Chef translation of
the DSC resource *InstallDSCReskit* given earlier as follows:

```ruby
    dsc_resource 'get-dsc-resource-kit' do 
      resource_name :Archive
      property :ensure, 'Present'
      property :path, "#{ENV['USERPROFILE']}/Downloads/DSC Resource Kit 03282014.zip"
      property :destination, "#{ENV['PROGRAMW6432']}/WindowsPowerShell/Modules"
    end
```

## TODO

### Tasks

* Additional prototyping
  * Better error handling / messages
* RFC in the public [Chef RFC repository](https://github.com/opscode/chef-rfc)
* Update `ohai` to detect PowerShell version 
* Direct integration into Chef rather than cookbook
* Caching of DSC resources to avoid DSC queries (if needed)
* Update `powershell` cookbook to obtain most recent PowerShell 5.0 CTP and
  release versions

### Open issues

* Namespacing -- is the "dsc_" prefix correct for DSC resources?
* Attribute collision: is collision detection + namespacing really the correct
  solution? Should we always namespace rather than be clever?
* How do we document resources? We can point to MSDN documentation, but the
  name mapping rules must understood by the user (e.g. everything must be
  lower case, use dsc_ prefix for Ruby keywords, etc).
  * Offer parallel docs for DSC resources (no way!)
  * Document the namespacing rules, point to them in some way from
    chef-client / knife
  * Create a knife-dsc plug-in that enumerates dsc resources on the system and
    shows the mapped names. (OK, though a little unorthodox).


# License #

Copyright:: Copyright (c) 2011-2013 Opscode, Inc.

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
