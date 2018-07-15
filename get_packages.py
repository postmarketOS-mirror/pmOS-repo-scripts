#!/usr/bin/env python3

"""
Copyright 2018 Oliver Smith

This file is part of pmbootstrap.

pmbootstrap is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

pmbootstrap is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with pmbootstrap.  If not, see <http://www.gnu.org/licenses/>.
"""

import argparse
import glob
import os

def get_arguments():
    parser = argparse.ArgumentParser(description="list pkgnames from a given"
                                                 " folder and architecture"
                                                 " (used internally by"
                                                 " build_all.sh)")
    parser.add_argument("--folder", help="aport subfolder (e.g. main)",
                        required=True)
    parser.add_argument("arch", help="architecture (e.g. armhf, noarch,"
                                     " all)", nargs="+")
    return parser.parse_args()


def check_arches(apkbuild, arches):
    # Find the arch= line
    line_arch = None
    with open(apkbuild, encoding="utf-8") as handle:
        lines = handle.readlines()
        for line in lines:
            if line.startswith("arch="):
                line_arch=line
                break
    if not line_arch:
        raise RuntimeError("Couldn't find arch= line in: " + apkbuild)

    # Parse into list
    line_arch = line_arch[len("arch="):-1]
    line_arch = line_arch.replace("'", "")
    line_arch = line_arch.replace("\"", "")
    arches_aport = line_arch.split(" ")

    # Compare with given arches
    for arch in arches:
        if arch in arches_aport:
            return True
    return False


def get_filtered_apkbuilds(folder, arches):
    script_dir = os.path.realpath(os.path.join(os.path.dirname(__file__)))
    aports_dir = script_dir + "/data/pmbootstrap/aports"
    pattern = aports_dir + "/" + folder + "/*/APKBUILD"
    ret = []
    for apkbuild in glob.glob(pattern):
        if check_arches(apkbuild, arches):
            ret += [apkbuild]
    return sorted(ret)


def print_pkgnames(apkbuilds):
    for apkbuild in apkbuilds:
        pkgname = apkbuild.split("/")[-2]
        print(pkgname)


def main():
    args = get_arguments()
    apkbuilds = get_filtered_apkbuilds(args.folder, args.arch)
    print_pkgnames(apkbuilds)

main()
