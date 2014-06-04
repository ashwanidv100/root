#! /bin/bash

###############################################################################
#
#                           The Cling Interpreter
#
# Cling Packaging Tool (CPT)
#
# tools/packaging/cpt.sh: Main script which calls other helper scripts to
# compile and package Cling for multiple platforms.
#
# TODO: Add documentation here, or provide link to documentation
#
# Author: Anirudha Bose <ani07nov@gmail.com>
#
# This file is dual-licensed: you can choose to license it under the University
# of Illinois Open Source License or the GNU Lesser General Public License. See
# LICENSE.TXT for details.
#
###############################################################################

# Uncomment the following line to trace the execution of the shell commands
# set -o xtrace

# TODO: Change workdir to a suitable path on your system (or Electric Commander)
workdir=~/ec/build
srcdir=${workdir}/cling-src
CLING_SRC_DIR=${srcdir}/tools/cling
HOST_CLING_SRC_DIR=$(dirname $(readlink -f ${0}))

# Import helper scripts here
source ${HOST_CLING_SRC_DIR}/indep.sh
source ${HOST_CLING_SRC_DIR}/debian/debianize.sh
source ${HOST_CLING_SRC_DIR}/windows/windows_dep.sh

function usage {
	cat <<- EOT
  Cling Packaging Tool

  Usage: ${0##/*/} [options]

  Options:
  -h|--help				Display this message and exit
  -c|--check-requirements		Check if packages required by the script are installed
  --current-dev={tar,deb}		Compile the latest development snapshot and produce a tarball/Debian package
  --last-stable={tar,deb}		Compile the last stable snapshot and produce a tarball/Debian package
  --tarball-tag={tag}			Compile the snapshot of a given tag and produce a tarball
  --deb-tag={tag}			Compile the snapshot of a given tag and produce a Debian package

EOT
}

while [ "${1}" != "" ]; do
  if [ "${#}" != "1" ]; then
    echo "Error: cannot handle multiple switches"
    usage
    exit
  fi

  echo "Cling Packaging Tool (CPT)"
  echo "Arguments passed: ${@}"
  box_draw_header
  echo "Operating System: ${OS}"
  echo "Distribution: ${DIST}"
  echo "Distro Based On: ${DistroBasedOn}"
  echo "Pseudo Name: ${PSEUDONAME}"
  echo "Revision: ${REV}"
  echo "Architecture: $(uname -m)"

  PARAM=$(echo ${1} | awk -F= '{print $1}')
  VALUE=$(echo ${1} | awk -F= '{print $2}')

  case ${PARAM} in
    -h | --help)
        usage
        exit
        ;;
    --check-requirements)
        box_draw "Check if required softwares are available on this system"
        if [ "${DIST}" = "Ubuntu" ]; then
          check_ubuntu git
          check_ubuntu curl
          check_ubuntu debhelper
          check_ubuntu devscripts
          check_ubuntu gnupg
          check_ubuntu python
          cat <<- EOT

Install/update the required packages by:
  sudo apt-get update
  sudo apt-get install git curl debhelper devscripts gnupg python
EOT
          exit
        elif [ "${OS}" = "Cygwin" ]; then
          check_cygwin cygwin # Doesn't make much sense. This is for the appeasement of users.
          check_cygwin cmake
          check_cygwin git
          check_cygwin python
          check_cygwin curl
          check_cygwin msvc
          cat <<- EOT
  Additional packages required in Windows (Cygwin):
  Microsoft Visual Studio 11 (2012), with Microsoft Visual C++

Refer to the documentation of CPT for information on setting up your Windows environment.

EOT
        fi

        ;;
    --current-dev)
        if [ "${VALUE}" = "" ]; then
          echo "Error: Expected a value"
          usage
          exit
        fi
        fetch_llvm
        fetch_clang
        fetch_cling master
        set_version
        if [ "${VALUE}" = "tar" ]; then
          if [ "${OS}" = "Cygwin" ]; then
            compile ${workdir}/cling-$(get_DIST)$(get_BIT)-${VERSION}
          else
            compile ${workdir}/cling-$(get_DIST)-$(get_REVISION)-$(get_BIT)bit-${VERSION}
          fi
          install_prefix
          test_cling
          tarball
          cleanup
        elif [ "${VALUE}" = "deb" ]; then
          compile ${workdir}/cling-${VERSION}
          install_prefix
          test_cling
          tarball_deb
          debianize
          cleanup_deb
        fi
        ;;
    --last-stable)
        if [ "${VALUE}" = "" ]; then
          echo "Error: Expected a value"
          usage
          exit
        fi
        fetch_llvm
        fetch_clang
        cd ${CLING_SRC_DIR}
        fetch_cling $(git describe --match v* --abbrev=0 --tags | head -n 1)

        if [ ${VALUE} = "tar" ]; then
          set_version
          if [ "${OS}" = "Cygwin" ]; then
            compile ${workdir}/cling-$(get_DIST)$(get_BIT)-${VERSION}
          else
            compile ${workdir}/cling-$(get_DIST)-$(get_REVISION)-$(get_BIT)bit-${VERSION}
          fi
          test_cling
          tarball
          cleanup
        elif [ ${VALUE} = "deb" ]; then
          VERSION=$(git describe --match v* --abbrev=0 --tags | head -n 1 | sed s/v//g)
          compile ${workdir}/cling-${VERSION}
          test_cling
          tarball_deb
          debianize
          cleanup_deb
        fi
        ;;
    --tarball-tag)
        fetch_llvm
        fetch_clang
        fetch_cling ${VALUE}
        VERSION=$(echo ${VALUE} | sed s/v//g)
        compile ${workdir}/cling-$(get_DIST)-$(get_REVISION)-$(get_BIT)bit-${VERSION}
        test_cling
        tarball
        cleanup
        ;;
    --deb-tag)
        fetch_llvm
        fetch_clang
        fetch_cling ${VALUE}
        VERSION=$(echo ${VALUE} | sed s/v//g)
        compile ${workdir}/cling-${VERSION}
        test_cling
        tarball_deb
        debianize
        cleanup_deb
        ;;
    *)
        echo "Error: unknown parameter \"${PARAM}\""
        usage
        exit 1
        ;;
  esac
  shift
done
