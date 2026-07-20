# vyos-stream-custom

Custom VyOS build source with MediaTek MT7922/MT7921E support.

The upstream build source lives as plain files in:

```text
upstream/vyos-build/
```

The local changes also live as portable patch files in:

```text
patches/
```

That gives two upgrade paths:

- Browse/build from the plain patched source tree directly.
- Refresh `upstream/vyos-build/` from a new upstream ref and reapply `patches/`.

## Build

```bash
docker run --rm --privileged \
  -v "$PWD:/repo" \
  -w /repo \
  -e VERSION=2026.03-mt7922 \
  vyos/vyos-build:circinus \
  bash -lc ./scripts/build.sh
```

Or run the `Build Custom VyOS` GitHub Actions workflow.

## Upgrade

Run the `Refresh Upstream Source` workflow with a new `vyos_build_ref`.
The workflow:

1. Clones the selected upstream `vyos-build` ref.
2. Replaces `upstream/vyos-build/` with that source as plain files.
3. Applies every patch in `patches/`.
4. Opens a PR with the resulting source-tree update.

Official VyOS Stream 2026.03 reports `build_git: 1cac4fd63750b0` on branch
`circinus`, but that commit is not currently reachable from public
`github.com/vyos/vyos-build` refs. Metadata for that official release is kept
in `upstream/stream-2026.03.json`.
