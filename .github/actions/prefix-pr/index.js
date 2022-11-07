const core = require("@actions/core");
const github = require("@actions/github");

const parsePullRequestId = (githubRef) => {
  const result = /refs\/pull\/(\d+)\/merge/g.exec(githubRef);
  if (!result) throw new Error("Reference not found.");
  const [, pullRequestId] = result;
  return pullRequestId;
};

async function run() {
  const githubToken = core.getInput("GITHUB_TOKEN");
  console.log("T O K E N: ", githubToken);
  const pullRequestId = parsePullRequestId(process.env.GITHUB_REF);
  const octokit = github.getOctokit(githubToken);

  const pr = await octokit.rest.pulls.get({
    owner: "Lombiq",
    repo: "GitHub-Actions",
    pull_number: pullRequestId,
  });

  let branch = pr;
  console.log(pr);
  let title = pr.data.title;
  let body = pr.data.body;

  console.log("title", title);
  console.log("body", body);

  await octokit.rest.pulls.update({
    owner: "Lombiq",
    repo: "GitHub-Actions",
    pull_number: pullRequestId,
    body: body,
    title: title,
  });
}

run();
