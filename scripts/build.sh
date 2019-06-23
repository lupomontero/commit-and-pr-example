# /usr/bin/env bash

if [[ "$TRAVIS_EVENT_TYPE" == "cron" ]]; then
  echo "Build triggered by Travis CI Cron"
fi

npm run update

git diff-index --quiet HEAD --
if [[ "$?" == 0 ]]; then
  echo "Already up to date."
  exit 0
fi

echo "Changes found!"
echo "Creating pull request..."
ts=$( date +%s )
branch="update-date-${ts}"
# git setup
git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"
# create branch and add commit changes
git checkout -b "${branch}"
git add .
git commit -m "chore(house-keeping): Updates date"
# Push changes and create PR
git remote -v
