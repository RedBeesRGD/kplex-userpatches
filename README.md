# kplex userpatches

Armbian build userpatches for the kplex kernel. `./build-base-image.sh` produces the **base
image**: stock Armbian ROCK 2F userspace, kernel built from `linux-kplex`. It is board-agnostic;
`rk35xx-kplex-armbian`'s `build-image.sh` turns it into a per-box image.

Checked out as `<armbian-build>/userpatches`, it builds in that tree and first moves it to the
pinned commit; anywhere else it builds in `../armbian-build` with a copy of this checkout.

| Input         | Pinned in                                                        |
| ------------- | ---------------------------------------------------------------- |
| Armbian build | `build-base-image.sh` — `ARMBIAN_BUILD_SHA`                      |
| Kernel source | `lib.config` — `KERNELBRANCH`                                    |
| Kernel config | `config/kernel/linux-rk35xx-kplex.config`                        |
| Board         | `config/boards/rock-2f.conf` — adds `kplex` to Armbian's ROCK 2F |

Bumping the kernel: push to `linux-kplex`, put the full commit in `lib.config`, rebuild. Every
kplex kernel reports `6.1.x-kplex-rk35xx`; `/boot/config-$(uname -r)` and the build date in
`uname -v` are what tell two apart.
