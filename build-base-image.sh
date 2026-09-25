#!/usr/bin/env bash
# Build the kplex base image: Armbian ROCK 2F userspace with the kplex kernel. Every input is
# pinned: Armbian build below, the kernel in lib.config, the kernel config in config/kernel/.
#   usage: ./build-base-image.sh [armbian-build-dir]
#   Checked out as <armbian-build>/userpatches, it builds in that tree; otherwise in the dir given
#   (default ../armbian-build), with a copy of this checkout as its userpatches.
#   RELEASE=trixie by default; anything Armbian builds for the ROCK 2F works.
set -euo pipefail

ARMBIAN_BUILD_REPO=https://github.com/armbian/build.git
ARMBIAN_BUILD_SHA=998cebde2dae965f7d0b50cb44a4c20ed951cfb3
RELEASE=${RELEASE:-trixie}

HERE="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$HERE/../compile.sh" ]; then
	DIR="$(cd "$HERE/.." && pwd)"
	NESTED=1
else
	DIR="$(mkdir -p "${1:-$HERE/../armbian-build}" && cd "${1:-$HERE/../armbian-build}" && pwd)"
	NESTED=0
	[ -d "$DIR/.git" ] || { git -C "$DIR" init -q && git -C "$DIR" remote add origin "$ARMBIAN_BUILD_REPO"; }
fi

# the build tree is pinned Armbian and nothing else: refuse to move it off uncommitted work
if [ -n "$(git -C "$DIR" status --porcelain --untracked-files=no)" ]; then
	echo "$DIR has uncommitted changes; commit or stash them first"; exit 1
fi
if [ "$(git -C "$DIR" rev-parse -q --verify HEAD || true)" != "$ARMBIAN_BUILD_SHA" ]; then
	git -C "$DIR" fetch -q --depth 1 "$ARMBIAN_BUILD_REPO" "$ARMBIAN_BUILD_SHA"
	git -C "$DIR" checkout -q FETCH_HEAD
fi

if [ "$NESTED" = 0 ]; then
	# a copy, not a symlink: Armbian builds in a container that only mounts its own tree
	rm -rf "$DIR/userpatches"
	mkdir -p "$DIR/userpatches"
	tar -C "$HERE" --exclude=.git --exclude=build-base-image.sh -cf - . | tar -C "$DIR/userpatches" -xf -
fi
echo "armbian build: $ARMBIAN_BUILD_SHA  userpatches: $(git -C "$HERE" describe --always --dirty)"

"$DIR/compile.sh" build \
	BOARD=rock-2f BRANCH=kplex RELEASE="$RELEASE" \
	BUILD_MINIMAL=yes BUILD_DESKTOP=no KERNEL_CONFIGURE=no \
	INSTALL_HEADERS=yes COMPRESS_OUTPUTIMAGE=sha,xz

ls -1 "$DIR"/output/images/*Rock-2f*kplex*.img.xz 2>/dev/null | tail -1
