#!/bin/bash
# build.sh [SERIES]
#
# Builds Vincent Rivière's m68k-atari-mintelf cross tools (binutils, mintbin
# and gcc, from ppa:vriviere/mintelf) for this machine's architecture, from
# the PPA's own source packages: the same versions, patches and
# configuration as his amd64 packages. Run it as root in a clean Ubuntu
# SERIES (default noble) for arm64, e.g.
#
#   docker run --rm --platform linux/arm64 -v "$PWD:/work" -w /work \
#     ubuntu:24.04 ./build.sh noble
#
# out/ then holds the .deb packages, the source packages they were built
# from (the GPL's corresponding source), their .buildinfo files and
# SHA256SUMS; notes.md describes them for a release.
set -euo pipefail
SERIES=${1:-noble}
. /etc/os-release
[ "$VERSION_CODENAME" = "$SERIES" ] || { echo "run this in Ubuntu $SERIES, not $VERSION_CODENAME" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get -y update
apt-get -y install build-essential dpkg-dev software-properties-common
# -s: the source packages too
add-apt-repository -y -s ppa:vriviere/mintelf
apt-get -y update

TOP=$PWD
rm -rf build out notes.md
mkdir build out
cd build
# binutils first: building gcc needs it installed
for p in binutils mintbin gcc; do
  pkg=$p-m68k-atari-mintelf
  apt-get source "$pkg"
  apt-get -y build-dep "$pkg"
  (cd "$pkg"-*/ && DEB_BUILD_OPTIONS="parallel=$(nproc) nocheck" dpkg-buildpackage -b -us -uc)
  apt-get -y install ./"$pkg"_*.deb
done
mv ./*.deb ./*.dsc ./*.tar.* ./*.buildinfo "$TOP/out/"

cd "$TOP/out"
# GitHub renames a release asset's ~ (in the PPA's versions) to a dot:
# rename them here, so SHA256SUMS names the files as they're published
shopt -s nullglob
for f in *~*; do
  mv -- "$f" "${f//\~/.}"
done
sha256sum -- * > SHA256SUMS
{
  echo "Built for Ubuntu $SERIES ($(dpkg --print-architecture)) from ppa:vriviere/mintelf's source packages:"
  echo
  for d in ./*.deb; do
    echo "- \`$(dpkg-deb -f "$d" Package)\` $(dpkg-deb -f "$d" Version)"
  done
  echo
  echo "Each package's source and .buildinfo are attached beside it; SHA256SUMS covers every file."
} > "$TOP/notes.md"
cat "$TOP/notes.md"
