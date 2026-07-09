#!/usr/bin/env bash
set -euo pipefail

fail() {
    echo "$1" >&2
    exit 1
}

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

version="${1:-$(tr -d '[:space:]' < VERSION)}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "expected plain semantic version like 2.4.0"
fi

eval "$(
    RELEASE_REQUIRE_REMOTE_TAG=1 \
    RELEASE_FETCH_ARCHIVE_META=1 \
    bash "$repo_root"/scripts/release-manifest.sh "$version"
)"
release_sha256="$RELEASE_ARCHIVE_SHA256"
release_sha512="$RELEASE_ARCHIVE_SHA512"
macports_rmd160="$RELEASE_MACPORTS_RMD160"
macports_sha256="$RELEASE_MACPORTS_SHA256"
macports_size="$RELEASE_MACPORTS_SIZE"

docs=(
    README.md
    docs/modules/av.md
    docs/modules/base.md
    docs/modules/http.md
    docs/modules/net.md
    docs/modules/webrtc.md
    llms.txt
)

current_version=$(tr -d '[:space:]' < VERSION)
[ "$current_version" = "$version" ] || fail "VERSION contains $current_version, expected $version"
grep -Eq '^PROJECT_NUMBER[[:space:]]*=[[:space:]]*'"$version"'$' Doxyfile \
    || fail "Doxyfile PROJECT_NUMBER is not synced to $version"

grep -Eq '^    version = "'"$version"'"$' packaging/conan/conanfile.py \
    || fail "packaging/conan/conanfile.py is not synced to $version"
grep -Eq '^  "'"$version"'":$' packaging/conan/conandata.yml \
    || fail "packaging/conan/conandata.yml is not synced to $version"
grep -Eq '^    url: "https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz"$' packaging/conan/conandata.yml \
    || fail "packaging/conan/conandata.yml source URL is not synced to $version"
grep -Fqx '    sha256: "'"$release_sha256"'"' packaging/conan/conandata.yml \
    || fail "packaging/conan/conandata.yml sha256 does not match the live release archive"
grep -Eq '^  "'"$version"'":$' packaging/conan-center-index/recipes/icey/all/conandata.yml \
    || fail "packaging/conan-center-index/recipes/icey/all/conandata.yml is not synced to $version"
grep -Eq '^    url: "https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz"$' packaging/conan-center-index/recipes/icey/all/conandata.yml \
    || fail "packaging/conan-center-index/recipes/icey/all/conandata.yml source URL is not synced to $version"
grep -Fqx '    sha256: "'"$release_sha256"'"' packaging/conan-center-index/recipes/icey/all/conandata.yml \
    || fail "packaging/conan-center-index/recipes/icey/all/conandata.yml sha256 does not match the live release archive"
grep -Eq '^[[:space:]]*"version": "'"$version"'"' packaging/vcpkg/icey/vcpkg.json \
    || fail "packaging/vcpkg/icey/vcpkg.json is not synced to $version"
grep -Eq '^pkgver='"$version"'$' packaging/arch/PKGBUILD \
    || fail "packaging/arch/PKGBUILD is not synced to $version"
grep -Eq '^pkgrel=1$' packaging/arch/PKGBUILD \
    || fail "packaging/arch/PKGBUILD should reset pkgrel=1 for a new release"
grep -Fqx "sha256sums=('$release_sha256')" packaging/arch/PKGBUILD \
    || fail "packaging/arch/PKGBUILD sha256 does not match the live release archive"
grep -Eq '^[[:space:]]*pkgver = '"$version"'$' packaging/arch/.SRCINFO \
    || fail "packaging/arch/.SRCINFO is not synced to $version"
grep -Eq '^[[:space:]]*pkgrel = 1$' packaging/arch/.SRCINFO \
    || fail "packaging/arch/.SRCINFO should reset pkgrel = 1 for a new release"
grep -Eq '^[[:space:]]*source = icey-'"$version"'.tar.gz::https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz$' packaging/arch/.SRCINFO \
    || fail "packaging/arch/.SRCINFO source URL is not synced to $version"
grep -Eq '^[[:space:]]*sha256sums = '"$release_sha256"'$' packaging/arch/.SRCINFO \
    || fail "packaging/arch/.SRCINFO sha256 does not match the live release archive"
grep -Eq '^  url "https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz"$' packaging/homebrew/Formula/icey.rb \
    || fail "packaging/homebrew/Formula/icey.rb source URL is not synced to $version"
grep -Eq '^  version "'"$version"'"$' packaging/homebrew/Formula/icey.rb \
    || fail "packaging/homebrew/Formula/icey.rb is not synced to $version"
grep -Fqx '  sha256 "'"$release_sha256"'"' packaging/homebrew/Formula/icey.rb \
    || fail "packaging/homebrew/Formula/icey.rb sha256 does not match the live release archive"
grep -Eq '^        REF "'"$version"'"$' packaging/vcpkg/icey/portfile.cmake \
    || fail "packaging/vcpkg/icey/portfile.cmake REF is not synced to $version"
grep -Fqx "        SHA512 $release_sha512" packaging/vcpkg/icey/portfile.cmake \
    || fail "packaging/vcpkg/icey/portfile.cmake SHA512 does not match the live release archive"
grep -Eq '^Version:[[:space:]]+'"${version}"'$' packaging/rpm/icey.spec \
    || fail "packaging/rpm/icey.spec is not synced to $version"
grep -Eq '^pkgver='"$version"'$' packaging/alpine/APKBUILD \
    || fail "packaging/alpine/APKBUILD is not synced to $version"
grep -Fqx "$release_sha512  icey-$version.tar.gz" packaging/alpine/APKBUILD \
    || fail "packaging/alpine/APKBUILD sha512 does not match the live release archive"
grep -Eq '^github.setup[[:space:]]+nilstate[[:space:]]+icey[[:space:]]+'"${version}"'$' packaging/macports/Portfile \
    || fail "packaging/macports/Portfile is not synced to $version"
grep -Eq '^checksums[[:space:]]+rmd160[[:space:]]+'"${macports_rmd160}"' \\$' packaging/macports/Portfile \
    || fail "packaging/macports/Portfile rmd160 does not match the live MacPorts archive"
grep -Eq '^[[:space:]]+sha256[[:space:]]+'"${macports_sha256}"' \\$' packaging/macports/Portfile \
    || fail "packaging/macports/Portfile sha256 does not match the live MacPorts archive"
grep -Eq '^[[:space:]]+size[[:space:]]+'"${macports_size}"'$' packaging/macports/Portfile \
    || fail "packaging/macports/Portfile size does not match the live MacPorts archive"
grep -Fqx '    version("'"$version"'", sha256="'"$release_sha256"'")' packaging/spack/package.py \
    || fail "packaging/spack/package.py sha256 does not match the live release archive"
grep -Fqx '    url = "https://github.com/nilstate/icey/archive/refs/tags/'"$version"'.tar.gz"' packaging/spack/package.py \
    || fail "packaging/spack/package.py URL is not synced to $version"
grep -Eq '^\{\% set version = "'"$version"'" \%\}$' packaging/conda-forge/meta.yaml \
    || fail "packaging/conda-forge/meta.yaml is not synced to $version"
grep -Fqx "  sha256: $release_sha256" packaging/conda-forge/meta.yaml \
    || fail "packaging/conda-forge/meta.yaml sha256 does not match the live release archive"
grep -Eq '^icey \('"$version"'-1\) ' packaging/debian/debian/changelog \
    || fail "packaging/debian/debian/changelog is not synced to $version-1"

grep -Eq '^    sha256: "0{64}"$' packaging/conan/conandata.yml \
    && fail "packaging/conan/conandata.yml still has a placeholder sha256"
grep -Eq '^  sha256 "0{64}"$' packaging/homebrew/Formula/icey.rb \
    && fail "packaging/homebrew/Formula/icey.rb still has a placeholder sha256"
grep -Eq '^        SHA512 0{128}$' packaging/vcpkg/icey/portfile.cmake \
    && fail "packaging/vcpkg/icey/portfile.cmake still has a placeholder SHA512"
grep -Eq '^0{128}[[:space:]]+icey-'"$version"'\.tar\.gz$' packaging/alpine/APKBUILD \
    && fail "packaging/alpine/APKBUILD still has a placeholder sha512"
grep -Eq '^checksums[[:space:]]+rmd160[[:space:]]+0{40} \\$' packaging/macports/Portfile \
    && fail "packaging/macports/Portfile still has a placeholder rmd160"
grep -Eq '^[[:space:]]+sha256[[:space:]]+0{64} \\$' packaging/macports/Portfile \
    && fail "packaging/macports/Portfile still has a placeholder sha256"
grep -Eq '^[[:space:]]+size[[:space:]]+0$' packaging/macports/Portfile \
    && fail "packaging/macports/Portfile still has a placeholder size"
grep -Eq '^    version\("'"$version"'", sha256="0{64}"\)$' packaging/spack/package.py \
    && fail "packaging/spack/package.py still has a placeholder sha256"
grep -Eq '^  sha256: 0{64}$' packaging/conda-forge/meta.yaml \
    && fail "packaging/conda-forge/meta.yaml still has a placeholder sha256"

for file in "${docs[@]}"; do
    grep -Eq 'GIT_TAG '"$version"'([^0-9]|$)' "$file" \
        || fail "$file does not reference GIT_TAG $version"
    if grep -En 'GIT_TAG ' "$file" | grep -Ev 'GIT_TAG '"$version"'([^0-9]|$)' >/dev/null; then
        fail "$file still contains a stale GIT_TAG reference"
    fi
done

grep -Eq "^## \\[$version\\]" CHANGELOG.md || fail "CHANGELOG.md is missing [$version]"

section=$(
    awk '/^## \['"$version"'\]/{found=1; next} /^## \[/{if(found) exit} found{print}' CHANGELOG.md
)
printf '%s\n' "$section" | grep -Eq '[^[:space:]]' \
    || fail "CHANGELOG.md [$version] section is empty"

echo "release metadata is in sync for $version"
