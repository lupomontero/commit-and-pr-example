# /usr/bin/env bash


gitSetup() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}


commitAndPushChanges() {
  echo "Changes found! Creating new branch and commitingc changes..."
  local branch="$1"
  git checkout -b "${branch}"
  git add .
  git commit -m "chore(house-keeping): Updates date"
  echo "Creating pull request..."
  git remote add origin-with-token https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git > /dev/null 2>&1
  git push --quiet --set-upstream origin-with-token "${branch}"
}

sendPR() {
  local branch="$1"
  curl \
    -X POST \
    -H "Authorization: token ${GH_TOKEN}" \
    -d "{\"title\":\"Updates date\",\"head\":\"${branch}\",\"base\":\"master\"}" \
    https://api.github.com/repos/${TRAVIS_REPO_SLUG}/pulls
}


if [[ "$TRAVIS_EVENT_TYPE" != "cron" || "$TRAVIS_NODE_VERSION" != "12" || "$TRAVIS_BRANCH" != "master" ]]; then
  echo "Not triggered by cron. Ignoring..."
  exit 0
fi


echo "Build triggered by Travis CI Cron"
npm run update
git diff-index --quiet HEAD --
if [[ "$?" == 0 ]]; then
  echo "Already up to date."
  exit 0
fi

ts=$( date +%s )
branch="update-date-${ts}"
gitSetup
commitAndPushChanges $branch
sendPR $branch
