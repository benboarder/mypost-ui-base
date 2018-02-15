# mypost-ui-base

A base _Docker_ container for MyPost UI builds.

Created for internal use; with the official `debian:jessie` distro.

Numerous containers have been compiled into a single `Dockerfile` script for ease-of-use.
Includes snippets from the following:
```
debian:jessie
buildpack-deps:jessie
buildpack-deps:jessie-scm
buildpack-deps:jessie-curl
node:8
```

To locally build a tagged container from the `Dockerfile` run:
```
docker build -t benboarder/mypost-ui-base:latest .
```

To use the latest version run:
```
docker pull benboarder:mypost-ui-base
```
