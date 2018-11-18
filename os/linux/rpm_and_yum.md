# yum & rpm

## yum

```text
# yum --help
Loaded plugins: fastestmirror
Usage: yum [options] COMMAND

List of Commands:

check          Check for problems in the rpmdb
check-update   Check for available package updates
clean          Remove cached data
deplist        List a package's dependencies
distribution-synchronization Synchronize installed packages to the latest available versions
downgrade      downgrade a package
erase          Remove a package or packages from your system
fs             Acts on the filesystem data of the host, mainly for removing docs/lanuages for minimal hosts.
fssnapshot     Creates filesystem snapshots, or lists/deletes current snapshots.
groups         Display, or use, the groups information
help           Display a helpful usage message
history        Display, or use, the transaction history
info           Display details about a package or group of packages
install        Install a package or packages on your system
list           List a package or groups of packages
load-transaction load a saved transaction from filename
makecache      Generate the metadata cache
provides       Find what package provides the given value
reinstall      reinstall a package
repo-pkgs      Treat a repo. as a group of packages, so we can install/remove all of them
repolist       Display the configured software repositories
search         Search package details for the given string
shell          Run an interactive yum shell
swap           Simple way to swap packages, instead of using shell
update         Update a package or packages on your system
update-minimal Works like upgrade, but goes to the 'newest' package match which fixes a problem that affects your system
updateinfo     Acts on repository update information
upgrade        Update packages taking obsoletes into account
version        Display a version for the machine and/or available repos.

Options:
  -h, --help            show this help message and exit
  -t, --tolerant        be tolerant of errors
  -C, --cacheonly       run entirely from system cache, don't update cache
  -c [config file], --config=[config file]
                        config file location
  -R [minutes], --randomwait=[minutes]
                        maximum command wait time
  -d [debug level], --debuglevel=[debug level]
                        debugging output level
  --showduplicates      show duplicates, in repos, in list/search commands
  -e [error level], --errorlevel=[error level]
                        error output level
  --rpmverbosity=[debug level name]
                        debugging output level for rpm
  -q, --quiet           quiet operation
  -v, --verbose         verbose operation
  -y, --assumeyes       answer yes for all questions
  --assumeno            answer no for all questions
  --version             show Yum version and exit
  --installroot=[path]  set install root
  --enablerepo=[repo]   enable one or more repositories (wildcards allowed)
  --disablerepo=[repo]  disable one or more repositories (wildcards allowed)
  -x [package], --exclude=[package]
                        exclude package(s) by name or glob
  --disableexcludes=[repo]
                        disable exclude from main, for a repo or for
                        everything
  --disableincludes=[repo]
                        disable includepkgs for a repo or for everything
  --obsoletes           enable obsoletes processing during updates
  --noplugins           disable Yum plugins
  --nogpgcheck          disable gpg signature checking
  --disableplugin=[plugin]
                        disable plugins by name
  --enableplugin=[plugin]
                        enable plugins by name
  --skip-broken         skip packages with depsolving problems
  --color=COLOR         control whether color is used
  --releasever=RELEASEVER
                        set value of $releasever in yum config and repo files
  --downloadonly        don't update, just download
  --downloaddir=DLDIR   specifies an alternate directory to store packages
  --setopt=SETOPTS      set arbitrary config and repo options
  --bugfix              Include bugfix relevant packages, in updates
  --security            Include security relevant packages, in updates
  --advisory=ADVS, --advisories=ADVS
                        Include packages needed to fix the given advisory, in
                        updates
  --bzs=BZS             Include packages needed to fix the given BZ, in
                        updates
  --cves=CVES           Include packages needed to fix the given CVE, in
                        updates
  --sec-severity=SEVS, --secseverity=SEVS
                        Include security relevant packages matching the
                        severity, in updates

  Plugin Options:
```

### yum 命令

- repolist
- clean all && makecache
- list
- search
- install/reinstall/erase/upgrade/downgrade
- info
- provides
- deplist
- groups

```text
Available Environment Groups:
   Minimal Install
   Compute Node
   Infrastructure Server
   File and Print Server
   Basic Web Server
   Virtualization Host
   Server with GUI
   GNOME Desktop
   KDE Plasma Workspaces
   Development and Creative Workstation
Available Groups:
   Compatibility Libraries
   Console Internet Tools
   Development Tools
   Graphical Administration Tools
   Legacy UNIX Compatibility
   Scientific Support
   Security Tools
   Smart Card Support
   System Administration Tools
   System Management
```

- /etc/yum.repos.d/
- /etc/yum.conf
- /etc/yum/

### yum 源

createrepo
yum-utils

### yum 插件

## rpm

```text
# rpm --help
Usage: rpm [OPTION...]

Query/Verify package selection options:
  -a, --all                        query/verify all packages
  -f, --file                       query/verify package(s) owning file
  -g, --group                      query/verify package(s) in group
  -p, --package                    query/verify a package file
  --pkgid                          query/verify package(s) with package identifier
  --hdrid                          query/verify package(s) with header identifier
  --triggeredby                    query the package(s) triggered by the package
  --whatrequires                   query/verify the package(s) which require a dependency
  --whatprovides                   query/verify the package(s) which provide a dependency
  --nomanifest                     do not process non-package files as manifests

Query options (with -q or --query):
  -c, --configfiles                list all configuration files
  -d, --docfiles                   list all documentation files
  -L, --licensefiles               list all license files
  --dump                           dump basic file information
  -l, --list                       list files in package
  --queryformat=QUERYFORMAT        use the following query format
  -s, --state                      display the states of the listed files

Verify options (with -V or --verify):
  --nofiledigest                   don't verify digest of files
  --nofiles                        don't verify files in package
  --nodeps                         don't verify package dependencies
  --noscript                       don't execute verify script(s)

Install/Upgrade/Erase options:
  --allfiles                       install all files, even configurations which might otherwise be skipped
  --allmatches                     remove all packages which match <package> (normally an error is generated if <package> specified multiple packages)
  --badreloc                       relocate files in non-relocatable package
  -e, --erase=<package>+           erase (uninstall) package
  --excludedocs                    do not install documentation
  --excludepath=<path>             skip files with leading component <path> 
  --force                          short hand for --replacepkgs --replacefiles
  -F, --freshen=<packagefile>+     upgrade package(s) if already installed
  -h, --hash                       print hash marks as package installs (good with -v)
  --ignorearch                     don't verify package architecture
  --ignoreos                       don't verify package operating system
  --ignoresize                     don't check disk space before installing
  -i, --install                    install package(s)
  --justdb                         update the database, but do not modify the filesystem
  --nodeps                         do not verify package dependencies
  --nofiledigest                   don't verify digest of files
  --nocontexts                     don't install file security contexts
  --noorder                        do not reorder package installation to satisfy dependencies
  --noscripts                      do not execute package scriptlet(s)
  --notriggers                     do not execute any scriptlet(s) triggered by this package
  --nocollections                  do not perform any collection actions
  --oldpackage                     upgrade to an old version of the package (--force on upgrades does this automatically)
  --percent                        print percentages as package installs
  --prefix=<dir>                   relocate the package to <dir>, if relocatable
  --relocate=<old>=<new>           relocate files from path <old> to <new>
  --replacefiles                   ignore file conflicts between packages
  --replacepkgs                    reinstall if the package is already present
  --test                           don't install, but tell if it would work or not
  -U, --upgrade=<packagefile>+     upgrade package(s)
  --reinstall=<packagefile>+       reinstall package(s)

Common options for all rpm modes and executables:
  -D, --define='MACRO EXPR'        define MACRO with value EXPR
  --undefine=MACRO                 undefine MACRO
  -E, --eval='EXPR'                print macro expansion of EXPR
  --macros=<FILE:...>              read <FILE:...> instead of default file(s)
  --noplugins                      don't enable any plugins
  --nodigest                       don't verify package digest(s)
  --nosignature                    don't verify package signature(s)
  --rcfile=<FILE:...>              read <FILE:...> instead of default file(s)
  -r, --root=ROOT                  use ROOT as top level directory (default: "/")
  --dbpath=DIRECTORY               use database in DIRECTORY
  --querytags                      display known query tags
  --showrc                         display final rpmrc and macro configuration
  --quiet                          provide less detailed output
  -v, --verbose                    provide more detailed output
  --version                        print the version of rpm being used

Options implemented via popt alias/exec:
  --scripts                        list install/erase scriptlets from package(s)
  --setperms                       set permissions of files in a package
  --setugids                       set user/group ownership of files in a package
  --conflicts                      list capabilities this package conflicts with
  --obsoletes                      list other packages removed by installing this package
  --provides                       list capabilities that this package provides
  --requires                       list capabilities required by package(s)
  --info                           list descriptive information from package(s)
  --changelog                      list change logs for this package
  --xml                            list metadata in xml
  --triggers                       list trigger scriptlets from package(s)
  --last                           list package(s) by install time, most recent first
  --dupes                          list duplicated packages
  --filesbypkg                     list all files from each package
  --fileclass                      list file names with classes
  --filecolor                      list file names with colors
  --fscontext                      list file names with security context from file system
  --fileprovide                    list file names with provides
  --filerequire                    list file names with requires
  --filecaps                       list file names with POSIX1.e capabilities

Help options:
  -?, --help                       Show this help message
  --usage                          Display brief usage message
```

### rpm 命令

- -q/--query
- -V/--verify
- -e/--erase
- -i/--install
- -U/--upgrade

### spec

rpmdevtools

## 常用包

```bash
for pkg in epel-release vim fish tmux git python-pip python-devel '@Development Tools'; do yum -y install $pkg; done
```
