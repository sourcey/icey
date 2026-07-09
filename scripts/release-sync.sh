#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <version>" >&2
    exit 1
fi

version="$1"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "expected plain semantic version like 2.4.0" >&2
    exit 1
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

if ! grep -Eq "^## \\[$version\\]" CHANGELOG.md; then
    echo "CHANGELOG.md is missing a section for [$version]" >&2
    exit 1
fi

docs=(
    README.md
    docs/modules/av.md
    docs/modules/base.md
    docs/modules/http.md
    docs/modules/net.md
    docs/modules/webrtc.md
    llms.txt
)

printf '%s\n' "$version" > VERSION
perl -0pi -e 's/^PROJECT_NUMBER[[:space:]]*=.*$/PROJECT_NUMBER         = '"$version"'/m' Doxyfile

perl -0pi -e 's/version = "\d+\.\d+\.\d+"/version = "'"$version"'"/' packaging/conan/conanfile.py
cat > packaging/conan/conandata.yml <<EOF
sources:
  "$version":
    url: "https://github.com/nilstate/icey/archive/refs/tags/$version.tar.gz"
    sha256: "0000000000000000000000000000000000000000000000000000000000000000"
EOF
cat > packaging/conan-center-index/recipes/icey/config.yml <<EOF
versions:
  "$version":
    folder: all
EOF
cat > packaging/conan-center-index/recipes/icey/all/conandata.yml <<EOF
sources:
  "$version":
    url: "https://github.com/nilstate/icey/archive/refs/tags/$version.tar.gz"
    sha256: "0000000000000000000000000000000000000000000000000000000000000000"
EOF
perl -0pi -e 's/"version": "\d+\.\d+\.\d+"/"version": "'"$version"'"/' packaging/vcpkg/icey/vcpkg.json
perl -0pi -e 's/^pkgver=\d+\.\d+\.\d+$/pkgver='"$version"'/m' packaging/arch/PKGBUILD
perl -0pi -e 's/^pkgrel=\d+$/pkgrel=1/m' packaging/arch/PKGBUILD
perl -0pi -e "s#^sha256sums=\\('[0-9a-f]+'\\)\$#sha256sums=('0000000000000000000000000000000000000000000000000000000000000000')#m" packaging/arch/PKGBUILD
perl -0pi -e 's/^[[:space:]]*pkgver = \d+\.\d+\.\d+$/\tpkgver = '"$version"'/m' packaging/arch/.SRCINFO
perl -0pi -e 's/^[[:space:]]*pkgrel = \d+$/\tpkgrel = 1/m' packaging/arch/.SRCINFO
perl -0pi -e 's#^[[:space:]]*source = [^[:space:]]+$#\tsource = icey-'"$version"'.tar.gz::https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz#m' packaging/arch/.SRCINFO
perl -0pi -e 's/^[[:space:]]*sha256sums = [0-9a-f]+$/\tsha256sums = 0000000000000000000000000000000000000000000000000000000000000000/m' packaging/arch/.SRCINFO
perl -0pi -e 's/REF "\d+\.\d+\.\d+"/REF "'"$version"'"/' packaging/vcpkg/icey/portfile.cmake
perl -0pi -e 's/SHA512 [0-9a-f]+/SHA512 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000/' packaging/vcpkg/icey/portfile.cmake
perl -0pi -e 's#url "https://github.com/nilstate/icey/archive/refs/tags/\d+\.\d+\.\d+\.tar\.gz"#url "https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz"#' packaging/homebrew/Formula/icey.rb
perl -0pi -e 's/version "\d+\.\d+\.\d+"/version "'"$version"'"/' packaging/homebrew/Formula/icey.rb
perl -0pi -e 's/sha256 "[0-9a-f]+"/sha256 "0000000000000000000000000000000000000000000000000000000000000000"/' packaging/homebrew/Formula/icey.rb
perl -0pi -e 's/^Version:\s+\d+\.\d+\.\d+$/Version:        '"$version"'/m' packaging/rpm/icey.spec
perl -0pi -e 's/^pkgver=\d+\.\d+\.\d+$/pkgver='"$version"'/m' packaging/alpine/APKBUILD
perl -0pi -e 's/^[0-9a-f]{128}[[:space:]]+icey-\d+\.\d+\.\d+\.tar\.gz$/00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000  icey-'"$version"'.tar.gz/m' packaging/alpine/APKBUILD
perl -0pi -e 's/github.setup\s+nilstate\s+icey\s+\d+\.\d+\.\d+/github.setup        nilstate icey '"$version"'/g' packaging/macports/Portfile
perl -0pi -e 's/^([[:space:]]*rmd160[[:space:]]+)[0-9a-f]{40}( \\\\)$/\10000000000000000000000000000000000000000\2/m' packaging/macports/Portfile
perl -0pi -e 's/^([[:space:]]*sha256[[:space:]]+)[0-9a-f]{64}( \\\\)$/\10000000000000000000000000000000000000000000000000000000000000000\2/m' packaging/macports/Portfile
perl -0pi -e 's/^([[:space:]]*size[[:space:]]+)\d+$/${1}0/m' packaging/macports/Portfile
perl -0pi -e 's#url = "https://github.com/nilstate/icey/archive/refs/tags/\d+\.\d+\.\d+\.tar\.gz"#url = "https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz"#' packaging/spack/package.py
perl -0pi -e 's/version\("\d+\.\d+\.\d+", sha256="[0-9a-f]+"\)/version("'"$version"'", sha256="0000000000000000000000000000000000000000000000000000000000000000")/' packaging/spack/package.py
perl -0pi -e 's/\{\% set version = "\d+\.\d+\.\d+" \%\}/{% set version = "'"$version"'" %}/' packaging/conda-forge/meta.yaml
perl -0pi -e 's/^  sha256: [0-9a-f]{64}$/  sha256: 0000000000000000000000000000000000000000000000000000000000000000/m' packaging/conda-forge/meta.yaml
perl -0pi -e 's/^icey \(\d+\.\d+\.\d+-\d+\) /icey ('"$version"'-1) /m' packaging/debian/debian/changelog
perl -0pi -e 's/^ -- .*$/ -- 0state OSS <oss\@0state.com>  '"$(date -R)"'/m' packaging/debian/debian/changelog

for file in "${docs[@]}"; do
    perl -0pi -e 's/GIT_TAG v?\d+\.\d+\.\d+/GIT_TAG '"$version"'/g' "$file"
done

echo "synced release metadata to $version"
echo "next: commit the release prep for $version"
echo "then: create and push the $version tag exactly once; never move a semver release tag"
echo "finally: make release-finalize VERSION=$version to pin the live archive metadata"
