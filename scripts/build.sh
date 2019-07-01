#! /usr/bin/env bash

if [[ "$TRAVIS_EVENT_TYPE" != "cron" || "$TRAVIS_NODE_VERSION" != "12" || "$TRAVIS_BRANCH" != "master" ]]; then
  echo "Not triggered by cron. Running tests..."
  npm test
else
  echo "Triggered by cron. Running update script..."
  npm run update && npm run commit-and-pr
fi
