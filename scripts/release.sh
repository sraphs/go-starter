#!/usr/bin/env bash

GIT_TAG=$(git describe --tags --always)
GIT_REPO_URL=$(git remote get-url origin | sed -e 's|git@\(.*\):\(.*\)\.git|https://\1/\2|g')
VERSION=${VERSION:-$GIT_TAG}

echo "New Version: ${VERSION}"
echo -n "Are you sure? [y/N]"
read ans && [ $${ans:-N} = y ]
echo -n "Please wait..."

cd $(dirname $0)

git-chglog --next-tag ${VERSION} --repository-url ${GIT_REPO_URL} -o ../CHANGELOG.md

cd -

git add CHANGELOG.md
git commit -m "🚀chore: update changelog for ${VERSION}" 
git tag ${VERSION}
git push origin main ${VERSION}