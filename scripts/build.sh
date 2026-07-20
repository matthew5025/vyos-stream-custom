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
command="${1:-all}"

prepare_dirs() {
  mkdir -p "${out_dir}" "${build_dir}/packages"
}

show_config() {
  jq . "${config}"
}

ccache_stats() {
  if command -v ccache >/dev/null 2>&1; then
    ccache --show-stats
  else
    echo "ccache is not installed"
  fi
}

build_kernel_packages() {
  prepare_dirs
  cd "${build_dir}/scripts/package-build/linux-kernel"
  ./build.py --config package.toml --packages linux-kernel linux-firmware
}

copy_packages() {
  local source_dir="$1"
  local matches=()

  shift
  for pattern in "$@"; do
    matches=("${source_dir}"/${pattern})
    if [[ ! -e "${matches[0]}" ]]; then
      echo "No package matched ${source_dir}/${pattern}" >&2
      exit 1
    fi
    cp "${matches[@]}" "${build_dir}/packages/"
  done
}

stage_packages() {
  prepare_dirs
  cd "${build_dir}"
  rm -f packages/*.deb
  copy_packages scripts/package-build/linux-kernel \
    "linux-headers-*-vyos_*_${architecture}.deb" \
    "linux-image-*-vyos_*_${architecture}.deb" \
    "linux-libc-dev_*_${architecture}.deb" \
    "linux-perf-*-vyos_*_${architecture}.deb" \
    "vyos-linux-firmware_*.deb"
  find packages -maxdepth 1 -type f -name "*.deb" -print -exec sha256sum {} \; | tee "${out_dir}/package-SHA256SUMS"
}

build_iso() {
  prepare_dirs
  cd "${build_dir}"
  ./build-vyos-image "${build_flavor}" \
    --architecture "${architecture}" \
    --build-by "${build_by}" \
    --build-type "${build_type}" \
    --version "${version}"
}

collect_outputs() {
  prepare_dirs
  cd "${build_dir}"
  cp build/*.iso "${out_dir}/"
  cp build/*.sha256 "${out_dir}/" 2>/dev/null || true
}

verify_outputs() {
  prepare_dirs
  shopt -s nullglob
  local isos=("${out_dir}"/*.iso)
  if (( ${#isos[@]} == 0 )); then
    echo "No ISO files found in ${out_dir}" >&2
    exit 1
  fi
  sha256sum "${isos[@]}" | tee "${out_dir}/SHA256SUMS"
}

run_all() {
  build_kernel_packages
  stage_packages
  build_iso
  collect_outputs
  verify_outputs
}

case "${command}" in
  all)
    run_all
    ;;
  show-config)
    show_config
    ;;
  ccache-stats)
    ccache_stats
    ;;
  kernel-packages)
    build_kernel_packages
    ;;
  stage-packages)
    stage_packages
    ;;
  iso)
    build_iso
    ;;
  collect)
    collect_outputs
    ;;
  verify)
    verify_outputs
    ;;
  *)
    echo "Usage: $0 [all|show-config|ccache-stats|kernel-packages|stage-packages|iso|collect|verify]" >&2
    exit 2
    ;;
esac
