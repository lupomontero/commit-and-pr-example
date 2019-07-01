# travis-cron-update-example

Example usage of [`commit-and-pr`](https://github.com/lupomontero/commit-and-pr).

`package.json`:

```json
{
  ...
  "scripts": {
    "update": "date > date.out",
    "commit-and-pr": "commit-and-pr"
  },
  ...
}
```

`.travis.yml`:

```yml
language: node_js
node_js:
  - 10
  - 12
script: ./scripts/build.sh
env:
  - secure: "XXXX="
```

`./scripts/build.sh`:

```sh
#! /usr/bin/env bash


if [[ "$TRAVIS_EVENT_TYPE" != "cron" || "$TRAVIS_NODE_VERSION" != "12" || "$TRAVIS_BRANCH" != "master" ]]; then
  echo "Not triggered by cron. Running tests..."
  npm test
else
  echo "Triggered by cron. Running update script..."
  npm run update && npm run commit-and-pr
fi
```

Make the script executable:

```sh
chmod +x scripts/build.sh
```

## Environment variables

Env vars used in our custom build script (`scripts/build.sh`) in order to decide
whether to simply run the tests or if it should run the update script.

* `TRAVIS_EVENT_TYPE`
* `TRAVIS_NODE_VERSION`
* `TRAVIS_BRANCH`

Env vars expected by `commit-and-pr`.

* `TRAVIS_REPO_SLUG`
* `GH_TOKEN`
