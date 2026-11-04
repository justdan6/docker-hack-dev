# Docker Hack development environment

A Docker-based [HHVM](https://hhvm.com/) development image, including Composer,
the Hack typechecker and linter, and HackTest. The image is built from the tracked
Dockerfile; source and dependencies are mounted at `/app` during development.

## Version limits

Verified against upstream package indexes on November 3, 2026:

| Component | Version |
| --- | --- |
| HHVM | 4.172.1 (last published Ubuntu package) |
| Ubuntu | 20.04, with all available public package updates |
| PHP (runs Composer only) | Ubuntu's 7.4 package, with available public updates |
| Composer | 2.11.1 |
| HSL | 4.108.1 |
| hhvm-autoload | 3.3.2 |
| hh-clilib | 2.6.0 |
| HackTest | 2.4.0 |
| FBExpect | 2.9.1 |

These are the latest available packages for this environment, **not a currently
maintained runtime stack**. HHVM [ended official releases](https://hhvm.com/blog/2023/10/27/oss-update.html).
The newer [HHVM 4.172.3 source tag](https://github.com/facebook/hhvm/tree/HHVM-4.172.3)
has no corresponding official Ubuntu package or Docker image. Later security
fixes [require compiling HHVM from source](https://hhvm.com/blog/2023/07/25/security-update.html).
Ubuntu 20.04's normal support has ended, and several Hack tools are marked
abandoned. This setup is for local development; rebuilding it does not make
those unsupported components current or suitable for public deployment.

The packaged HHVM binary depends on Ubuntu 20.04 libraries, so simply changing
the base image to a newer Ubuntu release will not work. Its download is pinned
by SHA-256 because `dl.hhvm.com` currently has an expired HTTPS certificate;
Composer downloads continue to use HTTPS and are also checksum-verified.

HHAST was removed because even its last release (4.168.3) rejects HHVM 4.172's
syntax-tree schema. `composer lint` uses HHVM's built-in `hh_client --lint`
instead. This checks Hack diagnostics; HHAST-specific style rules are no longer
available. `HHVM_DISABLE_PERSONALITY=true` lets the typechecker work with Docker's
default seccomp profile without changing container security settings.

## Start the environment

Install Docker Engine/Desktop and Docker Compose v2 or newer. On x86-64 Linux
or an Intel Mac, use your normal Docker context. On Apple Silicon, the image
runs as `linux/amd64`; if Docker Desktop reports an illegal instruction or
Rosetta error, use a full x86-64 QEMU VM with Colima:

```sh
brew install docker docker-compose qemu colima
# For an existing installation:
# brew update && brew upgrade docker docker-compose qemu colima

colima start --profile hack-dev --vm-type qemu --arch x86_64 \
  --cpu 4 --cpu-type max --memory 16 --network-address
docker context use colima-hack-dev
```

If Homebrew's Compose plugin is not found, follow the plugin setup printed by
`brew info docker-compose`. Use a separate Colima profile so other VMs are not
reconfigured. Stop this VM with `colima stop --profile hack-dev` when finished.

```sh
git clone https://github.com/justdan6/docker-hack-dev.git
cd docker-hack-dev
# On Linux, match the bind-mounted directory's owner:
# export HACK_UID=$(id -u)
docker compose build --pull
docker compose up -d --wait --wait-timeout 240
```

Open <http://localhost:8080/hello.hack>. The expected response is `Hello World!`.
Changes in `src/` are picked up without rebuilding the image. Composer installs
the committed lockfile before the server starts and stops startup on failure.
The service runs as the `hack` user, and the port is bound to localhost.
Set `PORT=8081` before `docker compose up` to use a different host port.

## Update and rebuild

After pulling updated repository files:

```sh
git pull --ff-only
docker compose build --pull --no-cache
docker compose up -d --force-recreate --wait --wait-timeout 240
docker compose exec hack-dev-ubuntu composer test
```

`--pull` refreshes the Ubuntu base image; `--no-cache` reruns package installation
to pick up available OS updates. `up --force-recreate` replaces the running
container with the rebuilt image. The bind-mounted source and `vendor/` remain
on your host. No volume deletion is needed.

To look for future Hack library updates, then regenerate and commit the lockfile:

```sh
docker compose run --rm --no-deps hack-dev-ubuntu composer outdated --direct
docker compose run --rm --no-deps hack-dev-ubuntu composer update --with-all-dependencies
```

Composer itself is pinned in `Dockerfile`. To update it later, change
`COMPOSER_VERSION` and `COMPOSER_SHA256` together using the checksum from the
[official downloads page](https://getcomposer.org/download/), then rebuild.
Update Docker Desktop through its updater, or update Docker Engine and the
Compose plugin through your OS package manager.

## Validate the build

```sh
docker compose run --rm --no-deps hack-dev-ubuntu composer install --prefer-dist
docker compose run --rm --no-deps hack-dev-ubuntu composer validate --no-check-publish
docker compose run --rm --no-deps hack-dev-ubuntu composer check-platform-reqs
docker compose run --rm --no-deps hack-dev-ubuntu composer test
docker compose run --rm --no-deps hack-dev-ubuntu composer lint
docker compose run --rm --no-deps hack-dev-ubuntu composer typecheck
curl --fail http://localhost:8080/hello.hack
```

GitHub Actions runs the build, dependency checks, tests, lint, typecheck, and
HTTP smoke test on x86-64 Linux for pushes and pull requests.

Inspect failures with `docker compose logs --tail=100`; stop the environment
with `docker compose down`. If APT reports invalid signatures during a build,
also check that Docker's VM has free disk space.
If a macOS bind mount fails with `operation not permitted`, grant Docker Desktop
access to the checkout's directory in macOS privacy/file-sharing settings, or
move the checkout into a directory Docker can already access.

## Publish the rebuilt image

Building locally does not update Docker Hub. If you maintain
`justdanz/hack-dev-ubuntu`, publish the tested image explicitly:

```sh
docker login
docker compose push hack-dev-ubuntu
```

To publish under a different Docker Hub account, change `image:` in
`compose.yaml` before building and pushing. This repository does not push images
automatically. Compose normally builds from source (`pull_policy: build`), so
`docker compose pull` alone is not the update workflow for this checkout.
