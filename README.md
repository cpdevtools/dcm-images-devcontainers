# dcm-images-devcontainers

Devcontainer base images for cpdevtools projects, published to
`ghcr.io/cpdevtools/dcm-images-devcontainers/<image>`.

| Image                          | Built on                    | Adds                                |
| ------------------------------ | --------------------------- | ----------------------------------- |
| `base-dc-image`                | `typescript-node:24-trixie` | Docker CLI, gh, Java 21, tsx, dcman |
| `typescript-dc-image`          | `base-dc-image`             | —                                   |
| `angular-dc-image`             | `base-dc-image`             | Angular CLI, Android SDK            |
| `dotnet-dc-image`              | `base-dc-image`             | .NET SDKs (stable line)             |
| `dotnet-edge-dc-image`         | `base-dc-image`             | .NET SDKs (latest line)             |
| `angular-dotnet-dc-image`      | `angular-dc-image`          | .NET SDKs (stable line)             |
| `angular-dotnet-edge-dc-image` | `dotnet-edge-dc-image`      | Angular CLI                         |

Each image is a workspace project under `projects/<image>/` with a `.devcontainer/` definition,
built with `devcontainer build`. Derived images `FROM <parent>:latest` — the local tag the parent's
build produced in the same run — so every image in a release is layered on that release's own base.

## Releases

Releases are driven by [cpdevtools/git-flow](https://github.com/cpdevtools/git-flow):

- Every push keeps a draft **release PR** (`release/<branch>`) up to date.
- Merging that PR builds all images in dependency order, packs them (`gitflow pack`) and publishes
  each to ghcr as `<image>:<version>` plus `latest`/`next` floating tags.
- Versions live in `.publish/versions.yml` (`0.0.0-MAIN` placeholder in every manifest). Bump with
  `pnpm gitflow version`.
- Release tags are `<image>/v<version>` per image, plus `MAIN/v<version>` and `v<version>`.

## Development

```bash
pnpm install
pnpm build                              # all images, dependency order
pnpm --filter base-dc-image run build   # one image → base-dc-image:latest
pnpm check                              # dependency pins + syncpack
pnpm fix                                # apply pins, format, drop local tags
```
