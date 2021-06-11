terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "deephaven"
    workspaces {
      name = "infra"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.9.0"
    }
  }
}

variable "github_token" {
  type        = string
  description = "The github personal token for authentication."
}

provider "github" {
  token        = var.github_token
  owner = "deephaven"
}

// ----------------------------------------------------------------------------

locals {
  github_membership_csv = file("github_membership.csv")
  github_membership_instances = csvdecode(local.github_membership_csv)

  github_team_membership_developers_csv = file("github_team_membership_developers.csv")
  github_team_membership_developers_instances = csvdecode(local.github_team_membership_developers_csv)

  github_team_membership_security_csv = file("github_team_membership_security.csv")
  github_team_membership_security_instances = csvdecode(local.github_team_membership_security_csv)

  github_team_membership_docs_csv = file("github_team_membership_docs.csv")
  github_team_membership_docs_instances = csvdecode(local.github_team_membership_docs_csv)
}

resource "github_membership" "member" {
  for_each = { for inst in local.github_membership_instances : inst.username => inst }
  username = each.value.username
  role = each.value.role
}

// ----------------------------------------------------------------------------

# Add a team to the organization
resource "github_team" "developers" {
  name        = "developers"
  description = "Deephaven Developers"
  privacy     = "closed" // todo: this really means Visible?
}

resource "github_team" "security" {
  name        = "security"
  description = "Deephaven Security Team"
  privacy     = "secret"
}

resource "github_team" "docs" {
  name        = "docs"
  description = "Deephaven Docs Team"
  privacy     = "closed"
}

resource "github_team" "qwinix" {
  name        = "qwinix"
  description = "qwinix.io Developers"
  privacy     = "secret"
}

resource "github_team_membership" "qwinix-ghorejsi" {
  team_id  = github_team.qwinix.id
  username = github_membership.member["BitFlippedCelt"].username
  role     = "member"
}

// ----------------------------------------------------------------------------

resource "github_team_membership" "developer" {
  for_each = { for inst in local.github_team_membership_developers_instances : inst.username => inst }
  team_id  = github_team.developers.id
  username = github_membership.member[each.value.username].username
  role = each.value.role
}

// ----------------------------------------------------------------------------

resource "github_team_membership" "security" {
  for_each = { for inst in local.github_team_membership_security_instances : inst.username => inst }
  team_id  = github_team.security.id
  username = github_membership.member[each.value.username].username
  role = each.value.role
}

// ----------------------------------------------------------------------------

resource "github_team_membership" "docs" {
  for_each = { for inst in local.github_team_membership_docs_instances : inst.username => inst }
  team_id  = github_team.docs.id
  username = github_membership.member[each.value.username].username
  role = each.value.role
}

// ----------------------------------------------------------------------------

resource "github_repository" "infra" {
  name    = "infra"
  visibility  = "private"
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "infra" {
  repository     = github_repository.infra.name
  branch         = "master"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "infra-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.infra.name
  permission = "push"
}

resource "github_repository_collaborator" "infra-mofojed" {
  repository = github_repository.infra.name
  username   = github_membership.member["mofojed"].username
  permission = "push"
}

resource "github_repository_collaborator" "infra-chipkent" {
  repository = github_repository.infra.name
  username   = github_membership.member["chipkent"].username
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "report-generation-plugin" {
  name        = "report-generation-plugin"
  description = "The report generation plugin enables users to create and send structured reports"
  topics      = ["deephaven", "database", "reports", "plugin"]
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "report-generation-plugin" {
  repository     = github_repository.report-generation-plugin.name
  branch         = "master"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}
  
resource "github_repository_collaborator" "report-generation-plugin-devinrsmith" {
  repository = github_repository.report-generation-plugin.name
  username   = github_membership.member["devinrsmith"].username
  permission = "admin"
}

// ----------------------------------------------------------------------------

resource "github_repository" "openapi-node-starter" {
  name        = "openapi-node-starter"
  description = "An example Node Client that connects and logs in"
  topics      = ["deephaven", "nodejs", "openapi"]
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "openapi-node-starter" {
  repository     = github_repository.openapi-node-starter.name
  branch         = "master"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}
  
resource "github_repository_collaborator" "openapi-node-starter-mattrunyon" {
  repository = github_repository.openapi-node-starter.name
  username   = github_membership.member["mattrunyon"].username
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "openapi-messaging" {
  name        = "openapi-messaging"
  description = "Uses OpenAPI to monitor PQs and send emails on failure"
  topics      = ["deephaven", "openapi", "messaging", "alerting"]
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "openapi-messaging" {
  repository     = github_repository.openapi-messaging.name
  branch         = "master"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}
  
resource "github_repository_collaborator" "openapi-messaging-mattrunyon" {
  repository = github_repository.openapi-messaging.name
  username   = github_membership.member["mattrunyon"].username
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "barrage" {
  name        = "barrage"
  description = "An arrow flight extension to support ticking datasets via IPC"
  topics      = ["deephaven", "database", "arrow", "flight", "barrage"]
  homepage_url = "https://deephaven.github.io/barrage/"
  pages {
      source {
        // unfortunately, can't have strong reference to github_branch.barrage-main.branch due to circular dependency
        branch = "main"
        path = "/docs"
      }
  }
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "barrage" {
  repository     = github_repository.barrage.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_branch" "barrage-main" {
  repository = github_repository.barrage.name
  branch     = "main"
}

resource "github_branch_default" "barrage-branch-default" {
  repository = github_repository.barrage.name
  branch     = github_branch.barrage-main.branch
}

resource "github_repository_collaborator" "barrage-nbauernfeind" {
  repository = github_repository.barrage.name
  username   = github_membership.member["nbauernfeind"].username
  permission = "push"
}

resource "github_team_repository" "barrage-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.barrage.name
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "covid-19-sir-modelling" {
  name        = "covid-19-sir-modelling"
  description = "Uses Markov chain Monte Carlo to estimate the parameters of an SIR model with COVID-19 data"
  topics      = ["covid-19", "deephaven", "python", "pymc3", "bayesian", "model", "markov-chain", "monte-carlo", "sir", "disease", "epidemiology"]
  delete_branch_on_merge = true
  vulnerability_alerts = true
}


// ----------------------------------------------------------------------------

resource "github_repository" "demo-app" {
  name        = "demo-app"
  description = "An example application"
  topics      = ["deephaven"]
  visibility  = "private"
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "demo-app" {
  repository     = github_repository.demo-app.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_repository_collaborator" "demo-app-mofojed" {
  repository = github_repository.demo-app.name
  username   = github_membership.member["mofojed"].username
  permission = "push"
}

resource "github_team_repository" "demo-app-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.demo-app.name
  permission = "pull"
}

// ----------------------------------------------------------------------------

resource "github_repository" "core" {
  name        = "deephaven-core"
  description = "Deephaven Community Core"
  topics      = ["deephaven"]
  visibility  = "public"
  has_issues = true
  has_wiki = true
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "core" {
  repository     = github_repository.core.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }

  required_status_checks {
    contexts = [
      "checks",
      "long-checks",
      "javadoc",
      "pydoc",
      "doc-labels"
    ]
  }
}

resource "github_team_repository" "core-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.core.name
  permission = "push"
}

resource "github_team_repository" "core-security" {
  team_id    = github_team.security.id
  repository = github_repository.core.name
  permission = "push"
}

resource "github_team_repository" "core-qwinix" {
  team_id    = github_team.qwinix.id
  repository = github_repository.core.name
  permission = "pull"
}

resource "github_branch" "core-main" {
  repository = github_repository.core.name
  branch     = "main"
}

resource "github_branch_default" "core-branch-default" {
  repository = github_repository.core.name
  branch     = github_branch.core-main.branch
}

resource "github_repository_collaborator" "core-mofojed" {
  repository = github_repository.core.name
  username   = github_membership.member["mofojed"].username
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "preview" {
  name        = "preview"
  description = "Deephaven Private Preview"
  topics      = ["deephaven"]
  visibility  = "private"
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "preview" {
  repository     = github_repository.preview.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "preview-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.preview.name
  permission = "push"
}

resource "github_team_repository" "preview-qwinix" {
  team_id    = github_team.qwinix.id
  repository = github_repository.preview.name
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "web-client-ui" {
  name        = "web-client-ui"
  description = "Deephaven Web Client UI"
  topics      = ["deephaven"]
  visibility  = "public"
  has_issues = true
  has_wiki = true
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "web-client-ui" {
  repository     = github_repository.web-client-ui.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "web-client-ui-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.web-client-ui.name
  permission = "push"
}

resource "github_team_repository" "web-client-ui-security" {
  team_id    = github_team.security.id
  repository = github_repository.web-client-ui.name
  permission = "push"
}

resource "github_repository_collaborator" "web-client-ui-mofojed" {
  repository = github_repository.web-client-ui.name
  username   = github_membership.member["mofojed"].username
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "js-plugin-template" {
  name        = "js-plugin-template"
  description = "A Template and Example Files for creating a Javascript Plugin"
  visibility  = "private" // todo: eventually public
  topics      = ["deephaven", "plugin", "javascript"]
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "js-plugin-template" {
  repository     = github_repository.js-plugin-template.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_branch" "js-plugin-template-main" {
  repository = github_repository.js-plugin-template.name
  branch     = "main"
}

resource "github_branch_default" "js-plugin-template-branch-default" {
  repository = github_repository.js-plugin-template.name
  branch     = github_branch.js-plugin-template-main.branch
}

resource "github_team_repository" "js-plugin-template-developers" {
  repository = github_repository.js-plugin-template.name
  team_id    = github_team.developers.id
  permission = "push"
}

// ----------------------------------------------------------------------------

// https://docs.github.com/en/github/building-a-strong-community/creating-a-default-community-health-file
resource "github_repository" "community" {
  name        = ".github"
  description = "The default community health files for Deephaven"
  visibility  = "public"
  topics      = ["deephaven", "community"]
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "community" {
  repository     = github_repository.community.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

// ----------------------------------------------------------------------------

resource "github_repository" "hash" {
  name        = "hash"
  description = "privimitive-friendly collections"
  visibility  = "public"
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "hash" {
  repository     = github_repository.hash.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "hash-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.hash.name
  permission = "pull"
}

// ----------------------------------------------------------------------------

resource "github_repository" "deephaven_io" {
  name        = "deephaven.io"
  description = "Source code for the deephaven.io website and public documentation."
  topics      = ["deephaven", "documentation"]
  visibility  = "private" // todo: eventually public
  has_issues  = true
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "deephaven_io" {
  repository     = github_repository.deephaven_io.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "deephaven_io-docs" {
  team_id    = github_team.docs.id
  repository = github_repository.deephaven_io.name
  permission = "push"
}

resource "github_repository_collaborator" "deephaven_io-dsmmcken" {
  repository = github_repository.deephaven_io.name
  username   = github_membership.member["dsmmcken"].username
  permission = "admin"
}

resource "github_repository_collaborator" "deephaven_io-chipkent" {
  repository = github_repository.deephaven_io.name
  username   = github_membership.member["chipkent"].username
  permission = "maintain"
  // Workaround for https://github.com/integrations/terraform-provider-github/issues/480
  permission_diff_suppression = true
}

resource "github_repository_collaborator" "deephaven_io-margaretkennedy" {
  repository = github_repository.deephaven_io.name
  username   = github_membership.member["margaretkennedy"].username
  permission = "maintain"
  // Workaround for https://github.com/integrations/terraform-provider-github/issues/480
  permission_diff_suppression = true
}

// ----------------------------------------------------------------------------

resource "github_repository" "SuanShu" {
  name        = "SuanShu"
  description = "Extension of original open-sourced math library, SuanShu."
  visibility  = "public"
  topics      = [ "math" ]
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "SuanShu" {
  repository     = github_repository.SuanShu.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "SuanShu-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.SuanShu.name
  permission = "pull"
}


// ----------------------------------------------------------------------------

resource "github_repository" "protobuf-marshaller-tools" {
  name        = "protobuf-marshaller-tools"
  description = "Minor protobuf marshaller tools to simplify custom marshaller implementations"
  visibility  = "public"
  topics      = [ "protobuf" ]
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "protobuf-marshaller-tools" {
  repository     = github_repository.protobuf-marshaller-tools.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "protobuf-marshaller-tools-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.protobuf-marshaller-tools.name
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "examples" {
  name        = "examples"
  description = "Deephaven Community Core examples"
  visibility  = "public"
  has_issues = true
  has_wiki = true
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "examples" {
  repository     = github_repository.examples.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "examples-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.examples.name
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "examples-private" {
  name        = "examples-private"
  description = "Private code used to produce the examples repo"
  visibility  = "private"
  has_issues = true
  has_wiki = true
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "examples-private" {
  repository     = github_repository.examples-private.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "examples-private-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.examples-private.name
  permission = "push"
}

// ----------------------------------------------------------------------------

resource "github_repository" "deephaven-blog" {
  name        = "deephaven-blog"
  description = "Deephaven Blog"
  visibility  = "private"
  has_issues = true
  has_wiki = false
  delete_branch_on_merge = true
  vulnerability_alerts = true
}

resource "github_branch_protection_v3" "deephaven-blog" {
  repository     = github_repository.examples-private.name
  branch         = "main"
  enforce_admins = true

  required_pull_request_reviews {
    dismiss_stale_reviews = true
    require_code_owner_reviews = true
    required_approving_review_count = 1
  }
}

resource "github_team_repository" "deephaven-blog-developers" {
  team_id    = github_team.developers.id
  repository = github_repository.deephaven-blog.name
  permission = "push"
}

