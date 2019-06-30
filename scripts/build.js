#! /usr/bin/env node


const https = require('https');
const childProcess = require('child_process');


const spawn = (cmd, args = [], opts = {}) => new Promise(
  (resolve, reject) => childProcess.spawn(cmd, args, opts)
    .on('close', code => (
      (code > 0)
        ? reject(new Error(`Command ${cmd} ${args.join(' ')} exited with code ${code}`))
        : resolve()
    ))
);


const runAndExit = promise => promise
  .then((data) => console.log(data) || process.exit(0))
  .catch(err => console.error(err) || process.exit(1));


const hasUnstagedChanges = opts => spawn(
  'git',
  ['diff-index', '--quiet', 'HEAD', '--'],
  opts,
)
  .then(() => false)
  .catch(() => true);


const setupGit = opts => spawn(
  'git',
  ['config', '--global', 'user.email', 'travis@travis-ci.org'],
  opts,
)
  .then(() => spawn(
    'git',
    ['config', '--global', 'user.name', 'Travis CI'],
    opts,
  ));


const createPullRequest = (branch, opts) => new Promise((resolve, reject) => {
  const payload = JSON.stringify({
    title: 'Updates date',
    head: branch,
    base: 'master',
  });
  const req = https.request({
    hostname: 'api.github.com',
    port: 443,
    path: `/repos/${opts.env.TRAVIS_REPO_SLUG}/pulls`,
    method: 'POST',
    headers: {
      'User-Agent': 'Node.js https.request',
      Authorization: `token ${opts.env.GH_TOKEN}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
    },
  });

  req.on('error', reject);

  req.on('response', (resp) => {
    // if (resp.statusCode > 201) {
    //   return reject(new Error(`Failed to create pull request (${resp.statusCode})`));
    // }
    const chunks = [];
    resp.setEncoding('utf8');
    resp.on('data', chunk => chunks.push(chunk));
    resp.on('end', () => {
      const responseJson = JSON.parse(chunks.join(''));
      console.log('statusCode', resp.statusCode);
      console.log('responseJson', responseJson);
      if (resp.statusCode > 201) {
        return reject(new Error(`Failed to create pull request (${resp.statusCode})`));
      }
      opts.stdio[1].write(`Pull request created. See ${responseJson.html_url}\n`);
      resolve();
    });
  });

  req.write(payload);
  req.end();
});


const commitAndPushChanges = (opts) => {
  const branch = `update-date-${Date.now()}`;
  return spawn('git', ['checkout', '-b', branch], opts)
    .then(() => setupGit(opts))
    .then(() => spawn('git', ['add', '.'], opts))
    .then(() => spawn('git', ['commit', '-m', '"chore(house-keeping): Updates date"'], opts))
    .then(() => spawn('git', ['remote', 'add', 'origin-with-token', `https://${opts.env.GH_TOKEN}@github.com/${opts.env.TRAVIS_REPO_SLUG}.git`], opts))
    .then(() => spawn('git', ['push', '--quiet', '--set-upstream', 'origin-with-token', branch], opts))
    .then(() => createPullRequest(branch, opts));
};


exports.update = opts => spawn('npm', ['run', 'update'], opts)
  .then(() => hasUnstagedChanges(opts))
  .then((shouldCommit) => (
    (shouldCommit)
      ? commitAndPushChanges(opts)
      : opts.stdio[1].write('Already up to date\n')
  ));


exports.test = opts => spawn('npm', ['test'], opts);


if (require.main === module) {
  const { cwd, env, stdout, stderr } = process;
  const opts = { env, cwd: cwd(), stdio: ['ignore', stdout, stderr] };

  runAndExit((
    (env.TRAVIS_EVENT_TYPE !== 'cron'
      || env.TRAVIS_NODE_VERSION !== '12'
      || env.TRAVIS_BRANCH !== 'master')
      ? console.log('Running normal build (tests)...') || exports.test(opts)
      : console.log('Build triggered by Travis Cron') || exports.update(opts)
  ));
}
