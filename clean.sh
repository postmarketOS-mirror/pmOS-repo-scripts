#!/bin/sh -e
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

# Removes binary packages for which no aport in the same version exists

# Script location
DIR="$(cd $(dirname $0); pwd -P)"
cd "$DIR"

PACKAGES="$DIR/data/work/packages"
ALL="$DIR/data/packages_all"

# Backup all packages
mkdir -p "$ALL"
echo ":: Sync local packages to backup folder: $ALL"
rsync \
	--links \
	--info=progress2 \
	--human-readable \
	--recursive \
	--size-only \
	"$PACKAGES"/* \
	"$ALL"

# Delete outdated ones
echo ":: Delete outdated packages from repository"
"$DIR/data/pmb_repo.sh" -y zap -m

echo ":: Remember to run 'build_all.sh' again, just to make sure."
