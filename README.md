# atarist-mintelf-arm64

Prebuilt arm64 packages of the `m68k-atari-mintelf` cross tools for
Ubuntu: gcc 13, binutils and mintbin, for building Atari ST, TT and
Falcon programs on arm64 Linux, such as Docker on an Apple Silicon Mac or
a Raspberry Pi.

[Vincent Rivière's `ppa:vriviere/mintelf`](https://launchpad.net/~vriviere/+archive/ubuntu/mintelf)
builds these three for amd64 only: its arm64 index has just the
architecture-independent libraries (MiNTLib, fdlibm, gemlib and so on).
This repository rebuilds the three from the PPA's own source packages, so
they have the same versions, patches and configuration as his amd64
packages, and publishes them as releases. They're made for
[atarist-toolkit-docker](https://github.com/sidecartridge/atarist-toolkit-docker),
so its arm64 image doesn't have to compile gcc every time it's built.

If the PPA starts publishing arm64 builds of these, use those instead.

## Releases

Each release is tagged by Ubuntu series, gcc version and build number, for
example `noble-13.3.0-1`, and holds:

- `binutils-m68k-atari-mintelf_*_arm64.deb`
- `mintbin-m68k-atari-mintelf_*_arm64.deb`
- `gcc-m68k-atari-mintelf_*_arm64.deb`
- the source package each was built from (`.dsc` and `.tar.gz`) and its
  `.buildinfo`
- `SHA256SUMS`

## Using them

On Ubuntu for arm64, add the PPA for the libraries the packages depend on,
then install the packages. Check them against checksums you've recorded,
not only against the release's own `SHA256SUMS`:

```sh
add-apt-repository -y ppa:vriviere/mintelf && apt-get -y update
R=https://github.com/neilrackett/atarist-mintelf-arm64/releases/download/noble-13.3.0-1
for f in binutils-m68k-atari-mintelf_..._arm64.deb mintbin-..._arm64.deb gcc-..._arm64.deb; do
  curl -fsSLO "$R/$f"
done
sha256sum -c expected.sha256       # your recorded checksums
apt-get -y install ./*.deb cross-mintelf-essential
```

The commands are then `m68k-atari-mintelf-gcc` and so on, as on amd64.

## Building

[`build.sh`](build.sh) does the whole build, in a clean Ubuntu container:

```sh
docker run --rm --platform linux/arm64 -v "$PWD:/work" -w /work ubuntu:24.04 ./build.sh noble
```

It adds the PPA with its sources, then builds binutils, mintbin and gcc in
that order, because building gcc needs binutils installed. The results go
to `out/`. gcc takes about 25 minutes on an M-series Mac.

Releases are built by the [Build](.github/workflows/build.yml) workflow,
run by hand on GitHub's native arm64 runner, so their build logs are
public. Leave the release tag empty to build only, as a workflow artifact.

When the PPA publishes a new version, run the workflow again with a new
tag.

## Licences

The packages are builds of Vincent Rivière's packaging of GNU binutils and
GCC (GPL version 3 or later; GCC's runtime libraries also carry the GCC
Runtime Library Exception) and mintbin (GPL version 2 or later). Their
source is attached to every release. The scripts in this repository are
under the GPL version 3; see [LICENSE](LICENSE).
