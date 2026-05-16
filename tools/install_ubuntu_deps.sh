#!/bin/bash

# Script for building in a Docker container on Travis.

set -e  # Exit on error.
set -x  # Make command execution verbose

git submodule update --init --recursive

export P4C_DEPS="bison \
             build-essential \
             cmake \
             curl \
             flex \
             g++ \
	     llvm \
             clang \
             libboost-dev \
             libboost-graph-dev \
             libboost-iostreams-dev \
             libfl-dev \
             libgc-dev \
             libgmp-dev \
	     libgrpc++-dev \
	     libgrpc-dev \
             pkg-config \
             python3 \
             python3-pip \
             python3-setuptools \
             tcpdump \
	     libprotobuf-dev \
	     protobuf-compiler \
	     doxygen xdot"

export P4C_EBPF_DEPS="libpcap-dev \
             libelf-dev \
             zlib1g-dev \
             iproute2 \
             iptables \
             net-tools"

export P4C_RUNTIME_DEPS="cpp \
                     libgc1c2 \
                     libgmp10 \
                     libgmpxx4ldbl \
                     python3"

# use scapy 2.4.5, which is the version on which ptf depends
export P4C_PIP_PACKAGES="ipaddr \
                          pyroute2 \
                          ply==3.8 \
                          scapy==2.4.5"

sudo apt-get update

sudo apt-get install -y --no-install-recommends \
  ${P4C_DEPS} \
  ${P4C_EBPF_DEPS} \
  ${P4C_RUNTIME_DEPS} \
  git

# we want to use Python as the default so change the symlinks
sudo ln -sf /usr/bin/python3 /usr/bin/python
sudo ln -sf /usr/bin/pip3 /usr/bin/pip

pip3 install wheel
pip3 install $P4C_PIP_PACKAGES
cd backends/ebpf
./build_libbpf
cd -
if [ -f `which psa_switch_CLI` ];then
tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
pushd "${tmp_dir}"
git clone https://github.com/p4lang/behavioral-model.git
cd behavioral-model
bash install_deps.sh
bash autogen.sh
./configure
make -j
sudo make install-strip
sudo ldconfig
popd
rm -rf "${tmp_dir}"
fi
# ! ------  BEGIN VALIDATION -----------------------------------------------
function build_gauntlet() {
  # For add-apt-repository.
  sudo apt-get install -y software-properties-common
  # Symlink the toz3 extension for the p4 compiler.
  mkdir -p extensions
  git clone -b stable https://github.com/p4gauntlet/toz3 extensions/toz3
  # The interpreter requires boost filesystem for file management.
  sudo apt install -y libboost-filesystem-dev
  # Disable failures on crashes
  CMAKE_FLAGS+="-DVALIDATION_IGNORE_CRASHES=ON "
}
. /etc/lsb-release
if [ ! "$DISTRIB_RELEASE" == "18.04" ];then
build_gauntlet
fi
# ! ------  END VALIDATION -----------------------------------------------
