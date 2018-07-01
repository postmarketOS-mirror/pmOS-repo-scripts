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

# Create the "data" folder
DIR="$(cd $(dirname $0); pwd -P)"
cd "$DIR"
mkdir -p data
cd data

# Clone pmbootstrap
[ -d pmbootstrap ] || git clone "https://gitlab.com/postmarketOS/pmbootstrap.git"

# Create wrapper script
if ! [ -e pmb_repo.sh ]; then
	( echo "#!/bin/sh"
	  echo "exec $DIR/data/pmbootstrap/pmbootstrap.py \\"
	  echo "	--port-distccd=9999 \\"
	  echo "	-c $DIR/data/pmbootstrap.cfg \\"
	  echo "	-w $DIR/data/work \"\$@\""
	) > pmb_repo.sh
	chmod +x pmb_repo.sh
fi

# Initialize config
yes "" | ./pmb_repo.sh init


# Symlink caches
for i in ~/.local/var/pmbootstrap/cache_*; do
	[ -e "$i" ] || break
	target="$DIR/data/work/$(basename "$i")"
	[ -e "$target" ] && continue
	ln -sv "$i" "$target"
done
