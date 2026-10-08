# Fork notes

This repository is the middle layer of a three-layer chain, modelled on the
Home Assistant Community Apps layout:

| Layer | Here | Community equivalent |
| ----- | ---- | -------------------- |
| App store | [kashif-khan/ha-apps](https://github.com/kashif-khan/ha-apps) | hassio-addons/repository |
| App packaging | this repository (`kashif-khan/app-homebox`) | hassio-addons/app-homebox |
| Application | [kashif-khan/homebox](https://github.com/kashif-khan/homebox) | sysadminsmedia/homebox |

- `main` mirrors `upstream/main` (hassio-addons/app-homebox) and is never
  committed to.
- `custom` holds our changes on top of it. Keep it rebased:
  `scripts/sync-upstream.sh` (`rerere` is enabled, so repeated conflicts are
  resolved automatically).
- The image is built from the `kashif-khan/homebox` tag named by
  `HOMEBOX_VERSION` in `homebox/Dockerfile`.

## Releasing

1. Tag the application: push `v<version>` to `kashif-khan/homebox`.
2. Set `HOMEBOX_VERSION` in `homebox/Dockerfile` to that version.
3. Publish a GitHub release `v<version>` on this repository. The Deploy
   workflow builds the images to `ghcr.io/kashif-khan/homebox` and sends an
   `update` event to `kashif-khan/ha-apps`, which refreshes the store entry.

Required repository secret: `DISPATCH_TOKEN`, a fine-grained token with
`contents: write` on `kashif-khan/ha-apps`.
