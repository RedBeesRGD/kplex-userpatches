#!/usr/bin/env bash
# Build the kplex base image: Armbian ROCK 2F userspace with the kplex kernel. Every input is
# pinned: Armbian build below, the kernel in lib.config, the kernel config in config/kernel/.
#   usage: ./build-base-image.sh [armbian-build-dir]      (default: ../armbian-build)
#   RELEASE=trixie by default; anything Armbian builds for the ROCK 2F works.
set -euo pipefail

ARMBIAN_BUILD_REPO=https://github.com/armbian/build.git
ARMBIAN_BUILD_SHA=998cebde2dae965f7d0b50cb44a4c20ed951cfb3
RELEASE=${RELEASE:-trixie}

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="$(mkdir -p "${1:-$HERE/../armbian-build}" && cd "${1:-$HERE/../armbian-build}" && pwd)"

if [ ! -d "$DIR/.git" ]; then
	git -C "$DIR" init -q
	git -C "$DIR" remote add origin "$ARMBIAN_BUILD_REPO"
fi
git -C "$DIR" fetch -q --depth 1 origin "$ARMBIAN_BUILD_SHA"
git -C "$DIR" checkout -q --force FETCH_HEAD

# a copy, not a symlink: Armbian builds in a container that only mounts its own tree
rm -rf "$DIR/userpatches"
mkdir -p "$DIR/userpatches"
tar -C "$HERE" --exclude=.git --exclude=build-base-image.sh -cf - . | tar -C "$DIR/userpatches" -xf -
echo "userpatches: $(git -C "$HERE" describe --always --dirty)"

"$DIR/compile.sh" build \
	BOARD=rock-2f BRANCH=kplex RELEASE="$RELEASE" \
	BUILD_MINIMAL=yes BUILD_DESKTOP=no KERNEL_CONFIGURE=no \
	INSTALL_HEADERS=yes COMPRESS_OUTPUTIMAGE=sha,xz

ls -1 "$DIR"/output/images/*Rock-2f*kplex*.img.xz 2>/dev/null | tail -1
