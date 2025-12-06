# Automatic GitHub Actions Reference Management

## Overview

This repository includes workflows and actions that automatically manage GitHub Actions (GHA) references in pull requests. When you modify actions or workflows, the system automatically updates all references to those changed items to point to the appropriate branch, ensuring that:

1. During PR development, references point to the PR branch so the latest changes are tested.
2. After PR approval, references are reverted to the base branch to prepare for merge.
3. Cascading updates are handled automatically (when changing an action causes its callers to need updates, which in turn causes their callers to need updates, etc.).

## Workflows

### `auto-manage-gha-refs`

Automatically updates GitHub Actions references in pull requests.

**Behavior:**

1. **On PR commits (without approval):**
   - Detects which actions/workflows were modified.
   - Updates all references to those items to point to the PR branch.
   - Commits and pushes the changes.
   - Posts a comment explaining the changes.
2. **On PR approval:**
   - Detects which actions/workflows were modified.
   - Reverts all references back to the base branch.
   - Commits and pushes the changes.
   - Posts a comment explaining the changes.
3. **On new commits after approval:** Repeats from the first step.

**Opt-out:**

To disable automatic reference management for a specific PR, add the `dont-auto-manage-gha-refs` label to the PR. When this label is present:
- The automatic update workflow will skip the PR.
- The validation workflow (see below) will run instead to verify references manually.

### `validate-this-gha-refs`

Validates that GitHub Actions references are correct. This workflow only runs for pull requests when the `dont-auto-manage-gha-refs` label is present, allowing manual control over reference management. It verifies that all references match the expected branch and fails if they don't.
