#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${CONFIG:-${root_dir}/custom-build.json}"
version="${VERSION:-$(jq -r '.version' "${config}")}"
architecture="$(jq -r '.architecture' "${config}")"
build_flavor="$(jq -r '.build_flavor' "${config}")"
build_type="$(jq -r '.build_type' "${config}")"
build_by="$(jq -r '.build_by' "${config}")"
build_dir="${root_dir}/upstream/vyos-build"
out_dir="${root_dir}/out"

mkdir -p "${out_dir}" "${build_dir}/packages"

cd "${build_dir}/scripts/package-build/linux-kernel"
./build.py --config package.toml --packages linux-kernel linux-firmware

cd "${build_dir}"
rm -f packages/*.deb
cp scripts/package-build/linux-kernel/linux-headers-*-vyos_*_amd64.deb packages/
cp scripts/package-build/linux-kernel/linux-image-*-vyos_*_amd64.deb packages/
cp scripts/package-build/linux-kernel/linux-libc-dev_*_amd64.deb packages/
cp scripts/package-build/linux-kernel/linux-perf-*-vyos_*_amd64.deb packages/
cp scripts/package-build/linux-kernel/vyos-linux-firmware_*.deb packages/
find packages -maxdepth 1 -type f -name "*.deb" -print -exec sha256sum {} \; | tee "${out_dir}/package-SHA256SUMS"

./build-vyos-image "${build_flavor}" \
  --architecture "${architecture}" \
  --build-by "${build_by}" \
  --build-type "${build_type}" \
  --version "${version}"

cp build/*.iso "${out_dir}/"
cp build/*.sha256 "${out_dir}/" 2>/dev/null || true
sha256sum "${out_dir}"/*.iso | tee "${out_dir}/SHA256SUMS"
