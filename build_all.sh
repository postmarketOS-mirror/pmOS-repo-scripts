#!/bin/sh
# Copyright 2018 Oliver Smith
#
# This file is part of pmOS-repository-scripts.
#
# pmOS-repository-scripts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pmOS-repository-scripts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pmOS-repository-scripts.  If not, see <http://www.gnu.org/licenses/>.

# Script location
DIR="$(cd $(dirname $0); pwd -P)"
cd "$DIR"

# Run pmbootstrap (with retries)
pmb() {
	max="100"
	success="false"
	for i in $(seq 1 "$max"); do
		[ "$i" != 0 ] &&
		echo "[$i/$max] pmbootstrap $@"
		if "$DIR/data/pmb_repo.sh" --timeout=900 "$@"; then
			success="true"
			break
		else
			# HACK: often cmake is the issue
			# this can be removed when pmbootstrap is able to kill
			# running processes in the chroots
			sudo killall cmake
			echo "COMMAND FAILED!"
		fi
	done
}

# Get device packages for a specific architecture
# $1: arch
get_packages_device() {
	( cd "$DIR/data/pmbootstrap/aports";
	  grep '^deviceinfo_arch=' $(find device -name 'deviceinfo') | grep "$1" | cut -d '/' -f 2 )
}

# Check for loop mode
if [ "$1" != "--loop" ]; then
	echo "NOTE: Pass '--loop' to run in loop mode!"
	set -e
fi

# Update the pmbootstrap repository
echo ":: update pmbootstrap repository"
cd "$DIR/data/pmbootstrap"
git pull || exit 1

# Build all packages
arches="x86_64 armhf aarch64 x86"
while true; do
	cd "$DIR/data/pmbootstrap/aports"

	# All arches
	for arch in $arches; do
		for folder in cross main kde maemo modem hybris; do
			# Folder's packages
			echo ":: $arch $folder"
			packages="$($DIR/get_packages.py --folder $folder $arch all noarch)"

			# Remove gcc-* from packages
			# Workaround: Compiling gcc-x86_64 for armhf (gcc-* for non-native arch in
			# general) pulls in build-base-armhf for some reason, does not use distcc
			# (because gcc compiles itself, and this makes it run in pure qemu, which
			# is super slow), and just fails to compile after two hours. So let's
			# disable it. If someone needs to cross-compile from armhf to x86_64, the
			# package will be built automatically by pmbootstrap on armhf.
			if [ "$folder" == "cross" ]; then
				for arch_package in $arches; do
					packages="$(echo "$packages" | grep -v "gcc-$arch_package")"
				done
			fi

			pmb build --strict --arch="$arch" $packages
		done
		# Device kernels
		echo ":: $arch device kernels"
		pmb build --strict --arch="$arch" \
			$($DIR/get_packages.py --folder "device" "$arch")

		# Device packages with --ignore-depends so they
		# don't pull in the firmware packages
		echo ":: $arch device packages"
		pmb build --ignore-depends --arch="$arch" \
			$(get_packages_device "$arch")
	done
	[ "$1" != "--loop" ] && break
	sleep 60
done
