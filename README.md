# postmarketOS repository scripts

Here are a bunch of shell scripts, that wrap around [`pmbootstrap`](https://github.com/postmarketOS/pmbootstrap) to build the packages for the official binary package repository.
**You will probably not need this!** The scripts are only used by ollieparanoid so far, so they haven't seen much testing and they don't have safety checks.
If you really want to run these, make sure to read every script before execution.

## `prepare.sh`
* You must execute this script, before you run any of the other scripts.
* Requirements:
  * rsync
  * You must have `pmbootstrap` checked out somewhere already
  * It must use the default work path of `~/.local/var/pmbootstrap`
  * The following folders should already exist in that work folder (so the caches can be shared):
    * `cache_apk_aarch64`, `cache_apk_armhf`, `cache_apk_x86`, `cache_apk_x86_64`
    * `cache_ccache_aarch64`, `cache_ccache_armhf`, `cache_ccache_x86`, `cache_ccache_x86_64`
    * `cache_distfiles`, `cache_git`, `cache_http`
  * If the folders don't exist yet, run `pmbootstrap init` and `pmbootstrap build hello-world --arch=aarch64 --force` etc.
  * "pmbootstrap" must be in PATH and point to `pmbootstrap.py`
  * LOTS of disk space, old packages are backed up locally without ever deleting them (this is on purpose)
* It will set up a new `data` folder right where the git repository of these repository scripts are (`data` is in `.gitignore`)
* Inside `data` you will have (`prepare.sh` doesn't create all of this, see the other scripts too)
  * `pmbotostrap`
    * fresh clone of the `pmbootstrap` git repository
    * will be used to build the packages for the binary repository
    * it should always point to the unmodified `master` branch, do not mess with it!
  * `pmb_repo.sh`: a wrapper, that executes `data/pmbootstrap/pmbootstrap.py` with a different config file and "work" path (the one `pmbootstrap init` asks for)
    * the work folder will be placed in `data/work`
    * PROTIP: put a symlink to `pmb_repo.sh` in your PATH, so you can run `pmb_repo.sh log`
  * that way you can have a regular `pmbootstrap` folder checked out somewhere in your system for testing stuff out on the same PC, without changing the binary repository.
  * all caches from the default work folder will get symlinked to `data/work/cache_*`, so they are shared
  * this means, you can speed up the build of a package for the repo by building it with your normal `pmbootstrap` installation (where it is allowed to switch between branches) first, then merging it, and then building it with the repo script again

## `build_all.sh`
* updates the `data/pmbootstrap` repository once
* builds all packages for a hardcoded list of aports folders (currently `cross main kde maemo luna modem`) for all architectures
* everything is built in `--strict` mode
* run `./build_all.sh --loop` to retry building everything forever (so it keeps on trying after download errors)
  * even with `--loop`, the repo only gets updated at the beginning!
* gcc cross-compilers are not built for all architectures, only for x86_64

## `upload.sh`
* requirements:
  * at least one rsync server
  * you must have an SSH key to these servers, configured without a password so we can upload automatically in background
  * put `user@servername` lines in `data/servers.cfg` (one server per line, e.g. `repomirror@postmarketos.org:12345`)
* runs the following actions in a loop
  * mirrors the current `data/work/packages` folder to `data/packages_snapshot` (with rsync)
  * mirrors the `data/packages_snapshot` folder to the primary postmarketOS mirrors in the Internet (also with rsync)
  * on failure, wait one minute and try again
  * wait for changed APKINDEX files (by diffing `data/work/packages/*/APKINDEX.tar.gz` with the version in the snapshots)
* `upload.sh` can be executed at the same time as `build_all.sh`, so already built packages can be uploaded while compiling more packages

## `clean.sh`
* backups all packages to `data/packages_all` (without ever deleting packages from `packages_all`!)
* runs `pmbootstrap zap -m` to delete all packages where no aport with a matching version exists
* make sure to run this after a successful `build_all.sh` only, otherwise you could delete old versions of packages without having built new ones first!
* when `upload.sh` runs the next time, the packages will get deleted on the servers as well

## `sync_packages_local.sh`
* uses rsync to make `~/.local/var/pmbootstrap/packages` an exact copy of the packages built for the binary repository (`data/work/packages`)
* this basically saves you from downloading all packages when using the regular `pmbootstrap`
