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
PACKAGES="$DIR/data/work/packages"
SNAPSHOT="$DIR/data/packages_snapshot"

if ! [ -e "$DIR/data/servers.cfg" ]; then
	echo "ERROR: missing $DIR/data/servers.cfg"
	exit 1
fi


mkdir -p "$SNAPSHOT"
initial="true"
while true; do
	# Wait for changed APKINDEXes
	if [ "$initial" == "false" ]; then
		echo ":: Waiting for changed APKINDEXes"
		while true; do
			changes="false"
			cd "$PACKAGES"
			for index in */APKINDEX.tar.gz README.html; do
				diff -q "$index" "$SNAPSHOT/$index" && continue
				changes="true"
			done
			[ "$changes" == "true" ] && break
			sleep 5
		done
	fi
	initial="false"
	date
	echo ":: Sync local packages snapshot"
	rsync \
		--links \
		--info=progress2 \
		--human-readable \
		--recursive \
		--size-only \
		--delete \
		"$PACKAGES"/* \
		"$SNAPSHOT"

	cd "$SNAPSHOT"
	for dest in $(cat "$DIR/data/servers.cfg"); do
		while true; do
			echo ":: Running rsync to $dest"
			rsync \
				--skip-compress="" \
				--compress-level=9 \
				--links \
				--info=progress2 \
				--human-readable \
				--recursive \
				--size-only \
				--delete-before \
				--include="*/*.apk,*/APKINDEX.tar.gz README.html" \
				--filter="P .htaccess" \
				. \
				"$dest" \
				&& break
				echo "rsync failed, not trying again!"
				exit 1
		done
	done
	echo ":: Rsync is done!"
	exit 0
done
