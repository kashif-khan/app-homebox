#!/usr/bin/env bash
# Publish a new app version: pin the fork tag in the Dockerfile and create the
# GitHub release. The release triggers the build and the store update.
#
# Usage: scripts/release.sh <version>      e.g. scripts/release.sh 0.27.0-rc.1-kk.6
#
# The tag v<version> must already exist on kashif-khan/homebox.
set -euo pipefail

FORK_REPO="kashif-khan/homebox"
APP_REPO="kashif-khan/app-homebox"
BRANCH="custom"

die() {
    echo "error: $*" >&2
    exit 1
}

version="${1:-}"
[[ -n "${version}" ]] || die "usage: $0 <version>   e.g. 0.27.0-rc.1-kk.6"
version="${version#v}"
tag="v${version}"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

[[ "$(git branch --show-current)" == "${BRANCH}" ]] || die "switch to ${BRANCH} first"
git diff --quiet && git diff --cached --quiet || die "commit or stash your changes first"

git ls-remote --exit-code --tags "git@github.com:${FORK_REPO}.git" "refs/tags/${tag}" > /dev/null \
    || die "tag ${tag} not found on ${FORK_REPO}; in the homebox repo run: git tag ${tag} && git push origin ${tag}"

if gh release view "${tag}" -R "${APP_REPO}" > /dev/null 2>&1; then
    die "release ${tag} already exists on ${APP_REPO}"
fi

sed -i "s|^ARG HOMEBOX_VERSION=.*|ARG HOMEBOX_VERSION=\"${version}\"|" homebox/Dockerfile
git diff --quiet || changed=1
[[ "${changed:-0}" == "1" ]] || echo "Dockerfile already pins ${version}"

prerelease=()
[[ "${version}" == *-* ]] && prerelease=(--prerelease)

echo "About to publish ${tag} on ${APP_REPO} from ${BRANCH}${prerelease:+ (pre-release)}."
read -r -p "Continue? [y/N] " answer
[[ "${answer}" == "y" || "${answer}" == "Y" ]] || {
    git checkout -- homebox/Dockerfile
    die "cancelled"
}

if [[ "${changed:-0}" == "1" ]]; then
    git commit -q -am "chore: release ${tag}"
fi
git push origin "${BRANCH}"

gh release create "${tag}" -R "${APP_REPO}" --target "${BRANCH}" "${prerelease[@]}" \
    --title "${tag}" --notes "Homebox fork ${tag}."

echo "Published. Follow the build with: gh run watch -R ${APP_REPO}"
