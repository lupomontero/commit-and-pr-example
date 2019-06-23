# /usr/bin/env bash


if [[ "$TRAVIS_NODE_VERSION" != "12" ]]; then
  echo "Not Node v12.x build. Ignoring..."
  exit 0
fi

if [[ "$TRAVIS_BRANCH" != "master" ]]; then
  echo "Not in master. Ignoring..."
  exit 0
fi

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
git remote add origin-with-token https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git > /dev/null 2>&1
git push --quiet --set-upstream origin-with-token "${branch}"


# send PR
curl \
  -X POST \
  -H "Authorization: token ${GH_TOKEN}" \
  -d "{\"title\":\"Updates date\",\"head\":\"${branch}\",\"base\":\"master\"}" \
  https://api.github.com/repos/${TRAVIS_REPO_SLUG}/pulls
