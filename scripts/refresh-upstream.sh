#!/usr/bin/env bash
set -euo pipefail

repo="${VYOS_BUILD_REPO:-https://github.com/vyos/vyos-build.git}"
ref="${VYOS_BUILD_REF:?Set VYOS_BUILD_REF to a branch, tag, or commit}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

git clone "${repo}" "${tmp_dir}/vyos-build"
git -C "${tmp_dir}/vyos-build" checkout "${ref}"
commit="$(git -C "${tmp_dir}/vyos-build" rev-parse HEAD)"

rm -rf "${root_dir}/upstream/vyos-build"
mkdir -p "${root_dir}/upstream"
cp -R "${tmp_dir}/vyos-build" "${root_dir}/upstream/vyos-build"
rm -rf "${root_dir}/upstream/vyos-build/.git"

cat > "${root_dir}/upstream/source.json" <<EOF
{
  "repo": "${repo}",
  "ref": "${ref}",
  "commit": "${commit}"
}
EOF

cd "${root_dir}"
git apply --3way patches/*.patch
