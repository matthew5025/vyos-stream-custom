#!/usr/bin/env bash
set -euo pipefail

repo="${VYOS_BUILD_REPO:-https://github.com/vyos/vyos-build.git}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${CONFIG:-${root_dir}/custom-build.json}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

repo="$(jq -r '.upstream.repo' "${config}")"
ref="$(jq -r '.upstream.ref' "${config}")"
expected_commit="$(jq -r '.upstream.commit // empty' "${config}")"

git clone "${repo}" "${tmp_dir}/vyos-build"
git -C "${tmp_dir}/vyos-build" checkout "${ref}"
commit="$(git -C "${tmp_dir}/vyos-build" rev-parse HEAD)"

if [[ -n "${expected_commit}" && "${expected_commit}" != "null" && "${commit}" != "${expected_commit}" ]]; then
  echo "Resolved commit ${commit} does not match custom-build.json upstream.commit ${expected_commit}" >&2
  echo "Update custom-build.json if this is an intentional upstream bump." >&2
  exit 1
fi

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
git add upstream/vyos-build upstream/source.json
git apply --3way --index patches/*.patch
