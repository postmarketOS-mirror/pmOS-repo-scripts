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

PACKAGES_REPO="$DIR/data/work/packages"
PACKAGES_REGULAR=~/.local/var/pmbootstrap/packages/

sudo rsync \
	--links \
	--info=progress2 \
	--human-readable \
	--recursive \
	--size-only \
	--delete \
	"$PACKAGES_REPO"/* \
	"$PACKAGES_REGULAR"
sudo chown -R 12345:12345 "$PACKAGES_REGULAR"
pmbootstrap index
