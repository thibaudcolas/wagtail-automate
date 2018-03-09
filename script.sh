#!/bin/bash

# Exit with nonzero exit code if anything fails
set -e

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    echo "PR builds are not supported".
    exit 1
fi

# https://github.com/travis-ci/dpl/blob/master/lib/dpl/provider/pages.rb

SOURCE_REPOSITORY="wagtail/wagtail"
SOURCE_DIR=$SOURCE_REPOSITORY
TARGET_REPOSITORY="thibaudcolas/wagtail"
SOURCE_BRANCH="master"
TARGET_BRANCH="dist/master"

SOURCE_REF="https://github.com/$SOURCE_REPOSITORY.git"

echo "Cloning ref '$SOURCE_REF' at branch '$SOURCE_BRANCH' in dir '$SOURCE_DIR'."
git clone --depth=50 --branch=$SOURCE_BRANCH $SOURCE_REF $SOURCE_DIR

echo "Restoring node_modules cache in '$SOURCE_DIR'."
mv node_modules $SOURCE_DIR || true
cd $SOURCE_DIR

echo "Installing client-side buid dependencies."
npm install

echo "Building client-side static files."
npm run dist

echo "Saving node_modules cache in '$SOURCE_DIR'."
mv node_modules ../../

echo "Make built static files visible to git. find:\n $(find wagtail -name ".gitignore")"
find wagtail -name ".gitignore" -exec rm {} \;

cd ../../

mkdir work
cd work

echo "Creating a brand new local repo from scratch in dir $(pwd)."
git init

echo "Create orphan branch $TARGET_BRANCH"
git checkout --orphan "$TARGET_BRANCH"

echo "Copying '$SOURCE_DIR' contents to '$(pwd)'."
rsync -r --exclude .git --delete "$SOURCE_DIR/" .

echo "Configuring git committer name and email."
git config user.name "Travis CI"
git config user.email "deploy@travis-ci.org"

echo "Preparing to deploy branch '$SOURCE_BRANCH' to branch '$TARGET_BRANCH'."
touch "deployed at $(date)"
git add -A .
git commit -qm "Deploy $SOURCE_REPOSITORY#$SOURCE_BRANCH to $TARGET_REPOSITORY:$TARGET_BRANCH'"
git show --stat-count=10 HEAD

echo "Doing the git push in dir '$(pwd)'."
# NEVER PRINT THIS TO THE CONSOLE/LOGS/STDIN.
git push --force --quiet "https://$GITHUB_TOKEN@github.com/$TARGET_REPOSITORY.git:$TARGET_BRANCH" "$TARGET_BRANCH":"$TARGET_BRANCH" > /dev/null 2>&1

git status
