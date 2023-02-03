const core = require('@actions/core');
const github = require('@actions/github');

async function run() {
  try {
    // Get inputs
    const issueQuery = core.getInput('ISSUE_QUERY');
    const assignee = core.getInput('ASSIGNEE');

    // Get authenticated GitHub client
    const client = new github.GitHub(process.env.GITHUB_TOKEN);

    // Search for the issue
    const issues = await client.search.issues({ q: issueQuery });
    const issue = issues.data.items[0];

    // Assign the issue to the PR author
    await client.issues.addAssignees({
      owner: issue.repository.owner.login,
      repo: issue.repository.name,
      issue_number: issue.number,
      assignees: [assignee],
    });

    // Set the success output
    core.setOutput('success', 'true');
  } catch (error) {
    core.setFailed(error.message);
  }
}

run();
