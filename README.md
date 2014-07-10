chef-dsc Cookbook
===============

DSC is a prototype Chef Resource that exposes PowerShell Desired State
Configuration (DSC) resources as Chef resources on the Microsoft Windows
operating system. It requires PowerShell 4.0 or later
which is available as part the Windows Management Foundation 4.0 components of Windows.

This library is distributed as a Chef cookbook, use knife to upload it to your
Chef server for usage and testing.

## Installation

To use this cookbook with knife, clone it into a directory named `chef-dsc` in your
cookbook path:

    git clone git@github.com:opscode/chef-dsc-prototype chef-dsc
    
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
    include_dsc 'archive'

    dsc_archive 'get-dsc-resource-kit' do
      dsc_ensure 'Present'
      path "#{ENV['USERPROFILE']}/Downloads/DSC Resource Kit 03282014.zip"
      destination "#{ENV['PROGRAMW6432']}/WindowsPowerShell/Modules"
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

Given a DSC resource *D* with properties *P* and desired property values *V*, let *R*
be a Chef resource with the following characteristics:

1. R is expressed in a Chef recipe using the normal Chef / Ruby syntax
2. *R* must be preceded in Ruby interpreter execution by the execution of the
`include_dsc` directive that takes the *PowerShell resource name* of *D* as a
`String` argument.
    > Example: the Chef code `include_dsc 'Group'` could be placed at the top of the recipe that contains *R*.
3. The Chef *short resource name* of *R* is equal to the *PowerShell resource
name* of *D* converted to all lower-case and preceded by the prefix `dsc_`.

    > For example, if the resource name of D is `WindowsFeature`, the short resource
    > name of *R* is `dsc_windowsfeature`.

4. For each property *p* in *P*, let *b* be the name of *p* in all lowercase.
Then there exists an attribute *a* such that one
of the following is true:
  1. *a* is named *b* preceded by the prefix `dsc_` iff *b* is identical to a
  keyword or other reserved element of the Ruby language
  2. *a* is named *b* preceded by the prefix `dsc_` iff *b* is identical to an
  existing attribute or method of the `Chef::Resource` base class
  3. *a* is named *b* iff neither of the above conditions applies

    > For example, a DSC property named `Path` would become `path` attribute in
    > Chef (rule #3 above). The DSC property named `Ensure` would become the attribute `dsc_ensure` because there is a
    > Ruby keyword called `ensure` (rule #1 above).

5. If the value *v* in *V* was assigned to a property *p* in *P*, there exists an
assignment of the value *c* to the attribute *a* in *R* that corresponds to *p* such that
the Ruby type of *c* is typed according to the following conditions:
  1. If the CLR type of *p* is a `float` or `int32` or `uint32`, *c*'s type is
  `Number`
  2. If the CLR type of *p* is a `boolean`, *c*'s type is either `FalseClass`
  or `TrueClass`
  3. Otherwise the type of *c* is `String`

    > Thus given an assignment fragment in a DSC configuraition such as `DiskSize = 5`, the corresponding attribute assigment in Chef would be `disksize 5`.

Putting all of these rules together, we can annotate the Chef translation of
the DSC resource *InstallDSCReskit* given earlier as follows:

```ruby
    include_dsc 'Archive' # Directive so we can use DSC's Archive resource

    dsc_archive 'get-dsc-resource-kit' do # DSC 'Archive' renamed to lowercase prefixed 'dsc_archive'
      dsc_ensure 'Present' # DSC's 'Ensure' renamed to lowercase, prefix 'dsc_ensure' to avoid 'ensure' Ruby keyword
      path "#{ENV['USERPROFILE']}/Downloads/DSC Resource Kit 03282014.zip" # 'Path' becomes 'path' set to a 'String' type
      destination "#{ENV['PROGRAMW6432']}/WindowsPowerShell/Modules" # 'Destination' becomes 'destination'
    end
```

## TODO

### Tasks

* Additional prototyping
  * Additional type safety
  * Better error handling / messages
* RFC in the public [Chef RFC repository](https://github.com/opscode/chef-rfc)
* Update `ohai` to detect PowerShell version 
* Direct integration into Chef rather than cookbook
* Don't just downcase names, probably snake case them if PowerShell is
  reliable about snake casing
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
