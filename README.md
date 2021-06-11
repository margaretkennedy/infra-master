# Deephaven Organization Infrastructure

This repo uses Terraform to manage the Github Deephaven organization, repositories, users, and permissions.

[Terraform+Github integration](https://registry.terraform.io/providers/integrations/github/4.3.0/docs)

The desired state of the world is described in a textual form. Terraform manages the process of comparing the current state vs the desired state, and essentially applies "deltas" to transform the current state into the desired state.

This allows a history of changes to be kept; as well as reviews and pre-deployment plans to be validated.

This process is carried out by
[Terraform Cloud](https://app.terraform.io/app/deephaven/workspaces/infra/runs), the free subscription. This allows for 5 users - (currently, only Devin a member.)

All changes are made by the user [deephaven-internal](https://github.com/deephaven-internal). It should typically be unnecessary for users to log-in under this account. In circumstances where this is necessary, the credentials can be retreived via LastPass.


## Example repo creation

This will create a new repo named `deephaven/my-repo` and give all developers write permissions.

```
resource "github_repository" "my-repo" {
  name        = "my-repo"
  description = "This is where the description goes"
  topics      = ["deephaven", "some-topic"]
  visibility  = "public"
  has_issues  = true
}

resource "github_team_repository" "my-repo-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.my-repo.name
  permission = "pull"
}
```

To see all options available to "github_repository", see [github_repository docs](https://registry.terraform.io/providers/integrations/github/4.3.0/docs/resources/repository).

## Fixing state

Currently, the Github provider does not handle repository renaming very well.
See [terraform-provider-github#744](https://github.com/integrations/terraform-provider-github/issues/744)
and [terraform-provider-github#616](https://github.com/integrations/terraform-provider-github/issues/616).

For example, to change a repository name, this is the procedure:

0) Backup terraform state (from terraform web UI, or DL locally).
1) Manually rename the repository on GitHub.
2) Create temporary GitHub personal access token
3) Replace token = var.github_token with your PAT.
4) cd terraform
5) terraform init
6) terraform state rm github_repository.ref # note: this only removes the state from terraform, *not* deleting it.
7) Remove all states that refer to github_repository.ref.name
8) terraform import github_repository.ref <...>
9) Import all removed states. See [docs](https://registry.terraform.io/providers/integrations/github/latest/docs) for specific syntax for each resource.
11) Remove PAT from files
10) Edit github_repository.ref with the proper name; and update any other states that were manually updated outside of terraform.
12) Push changes to deephaven/infra PR (don't accidentally push PAT)
13) Check that the workflow run is a no-op (nothing to add, change, or delete). If there is a change, go back to step 10 and edit as proper and try again.
14) Delete PAT from Github
15) Merge PR.
16) Ensure Terraform run is still no-op.
17) Apply Terraform run via terraform web UI.