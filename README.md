# dsc Cookbook
[![Build Status](https://travis-ci.org/chef-cookbooks/dsc.svg?branch=master)](http://travis-ci.org/chef-cookbooks/dsc) [![Cookbook Version](https://img.shields.io/cookbook/v/dsc.svg)](https://supermarket.chef.io/cookbooks/dsc)

# DEPRECATED
This cookbook demonstrated **prototype** functionality to expose PowerShell Desired State Configuration (DSC) resources as Chef resources on the Microsoft Windows operating system. Chef 12.2 implemented this functionality into core chef so this cookbook is no longer necessary or maintained.

## Installation
To use this cookbook with knife, clone it into a directory in your cookbook path:

```
git clone https://github.com/chef-cookbooks/dsc.git
```

## Usage
Upload the cookbook to your Chef server to use it.

### Recipes
The cookbook contains the following recipes, still being updated:
- getdscresourcekit: Will download and install DSC Resource kit powershell modules using DSC
- dsc_demo: Creates a security group with one member using DSC

### Resources
All DSC resources on a system that are returned by the command below on that system will be visible as Chef resources on that system:

```
get-dscresource
```

As an example, consider the following DSC `Archive` resource returned from `get-dscresource`:

```
> Get-DscResource archive
ImplementedAs Name     Module                      Properties
------------- ----     ------                      ----------
PowerShell    Archive  PSDesiredStateConfiguration {Destination, Path, Checksum, DependsOn...}
```

That `Archive` resource itself contains the following _properties_ which can also be obtained via the `get-dscresource` command:

```
> Get-DscResource archive | Select-Object -ExpandProperty Properties
```

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

If you depend on this cookbook in your own cookbook, you can then write a recipe that includes the following `dsc_resource` Chef resource, which in this case exposes the DSC `Archive` resource in Chef's Domain Specific Language (DSL) like every other resource in Chef:

```ruby
    dsc_resource 'DSCReskitFromModules' do
      resource :archive
      property :ensure, 'Present'
      property :path, "#{ENV['USERPROFILE']}/Downloads/DSC Resource Kit 03282014.zip"
      property :destination, "#{ENV['PROGRAMW6432']}/WindowsPowerShell/Modules"
    end
```

The example above will translate the _attributes_ of the `dsc_resource` to _properties_ of DSC `Archive` resource, which is then presented to DSC's _Local Configuration Manager (LCM)_ to make changes to the operating system. From a DSC standpoint, the Chef fragment above is analogous to the DSC fragment below:

```
configuration 'InstallDSCReskit'
{
    Archive 'DSCReskitFromModules'
    {
        Ensure = 'Present'
        Path = "$env:USERPROFILE/Downloads/DSC Resource Kit 03282014.zip"
        Destination = "$env:PROGRAMW6432/WindowsPowerShell/Modules"
    }
}
```

More details on the correspondence between usage of a DSC resource within the PowerShell configuration DSL and the use of that same resource from within Chef's DSL is given below.

### Mapping PowerShell DSC resources to Chef resources
If you've used MSDN documentation or the `get-dscresource` cmdlet to discover DSC resources and their semantics / usage, you can use the following simple rules to take the knowledge of those DSC resources and express them in Chef recipes as Chef resources:
1. To use a DSC resource in Chef, use the `dsc_resource` resource in your recipe
2. Set the `resource` attribute to the name of the resource as a symbol, i.e. `WindowsFeature` in DSC becomes
3. `:windowsfeature`.
4. For each property in the DSC resource for which you want to declare a desired value, use the syntax

```ruby
   property :property_name, value
```

That's it -- note that case _does not_ matter for any of the symbols given above, which is also true of names expressed in the DSC DSL.

For example, we can annotate the Chef translation of the DSC resource _InstallDSCReskit_ given earlier as follows:

```ruby
    dsc_resource 'get-dsc-resource-kit' do
      resource :Archive
      property :ensure, 'Present'
      property :path, "#{ENV['USERPROFILE']}/Downloads/DSC Resource Kit 03282014.zip"
      property :destination, "#{ENV['PROGRAMW6432']}/WindowsPowerShell/Modules"
    end
```

## TODO
Many of the tasks below will be completed outside of this cookbook as the functionality is implemented in `chef-client`.

### Tasks
- Additional prototyping
  - Better error handling / messages

- Implement "embedded" DSC resource `dsc_script` and `dsc_mof` that allow embedded PowerShell or mof directly in recipes to
- enable re-use.
- RFC in the public [Chef RFC repository](https://github.com/chef/chef-rfc)
- Update `ohai` to detect PowerShell version
- Direct integration into Chef rather than cookbook
- Caching of DSC resources to avoid DSC queries (if needed)
- release versions
- Alternative to shelling-out to powershell.exe for each interaction with LCM
- Disallow "problematic" properties such as `dependson`.

### Open issues
None currently identified, but more will probably arise once an official RFC is posted on [https://github.com/chef/chef-rfc](https://github.com/chef/chef-rfc).

### Resolved issues
- Namespacing -- is the "dsc_" prefix correct for DSC resources?
  - **Resolution:** move to single Chef resource for all DSC resources rather than one Chef resource per DSC resource, which
  - obviates the need for any prefix to avoid name collisons.

- Attribute collision: is collision detection + namespacing really the correct
- solution? Should we always namespace rather than be clever?
  - **Resolution:** Don't translate attributes directly, use a single attribute that can express the desired state for a DSC
  - property given its value. Also, if the attribute translation were to be retained, it appears that always prefixing with a
  - dsc "namespace" would have been preferable.

- How do we document resources? We can point to MSDN documentation, but the
- name mapping rules must be understood by the user (e.g. everything must be
- lower case, use dsc_ prefix for Ruby keywords, etc).
  - **Resolution:** The decision to use a single Chef resource for all DSC resources that itself uses a single attribute
  - (expressed multiple times) for each DSC property simplifies this significantly. See the discussion earlier where the use
  - of MSDN/TechNet documentation with some straightforward rules that require no syntactic modifications (e.g. namespacing or
  - capitalization changes) are used so that knowledge from documentation can be used to easily access DSC resources from
  - Chef. Rejected approaches include those below:
    - Offer parallel docs for DSC resources (no way!)
    - Document the namespacing rules, point to them in some way from chef-client / knife
    - Create a knife-dsc plug-in that enumerates dsc resources on the system and shows the mapped names. (OK, though a little unorthodox).

# License

```text
Copyright:: Copyright (c) 2011-2015 Chef Software, Inc.


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
