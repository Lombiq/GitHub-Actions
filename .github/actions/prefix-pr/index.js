const core = require("@actions/core");
const github = require("@actions/github");

const parsePullRequestId = (githubRef) => {
  const result = /refs\/pull\/(\d+)\/merge/g.exec(githubRef);
  if (!result) throw new Error("Reference not found.");
  const [, pullRequestId] = result;
  return pullRequestId;
};

async function run() {
  const jiraUrl = "https://lombiq.atlassian.net/browse/";
  const githubToken = core.getInput("GITHUB_TOKEN");
  const pullRequestId = parsePullRequestId(process.env.GITHUB_REF);
  const [owner, repo] = process.env.GITHUB_REPOSITORY.split("/");
  const octokit = github.getOctokit(githubToken);

  const pr = await octokit.rest.pulls.get({
    owner: owner,
    repo: repo,
    pull_number: pullRequestId,
  });

  const branch = process.env.GITHUB_ACTION_REF;
  if (!branch.includes("issue")) {
    return;
  }

  const issueKey = branch.replace("issue/", "");
  const issueLink = `[${issueKey}](${jiraUrl + issueKey})`;

  let title = pr.data.title;
  if (!title.includes(issueKey)) {
    title = issueKey + ": " + title;
  }

  let body = pr.data.body;
  if (!body) {
    body = issueLink;
  }
  else if (!body.includes(issueKey)) {
    body = issueLink + "\n" + body;
  }
  else if (!body.includes(issueLink)) {
    body = body.replace(issueKey, issueLink);
  }

  await octokit.rest.pulls.update({
    owner: owner,
    repo: repo,
    pull_number: pullRequestId,
    body: body,
    title: title,
  });
}

run();
