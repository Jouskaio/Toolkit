# Cheatsheet git flow - Branches, features, releases

Branches: `main` (what is released, tagged), `develop` (the next release), `feature/*`, `release/*`, `hotfix/*`, `bugfix/*`.

| Topic   | Command | Command details                                | Description                                                                  |
|---------|---------|------------------------------------------------|------------------------------------------------------------------------------|
| setup   | init    | `git flow init -d`                             | Set up git flow with the default branch names                                |
| feature | start   | `git flow feature start my-feature`            | New branch `feature/my-feature` from `develop`                               |
| feature | finish  | `git flow feature finish my-feature`           | Merge it into `develop` and delete the branch                                |
| bugfix  | start   | `git flow bugfix start my-fix`                 | Same as a feature, for a fix of `develop`                                    |
| release | start   | `git flow release start v1.2.0`                | Branch `release/v1.2.0` from `develop`: version bump and last fixes only     |
| release | finish  | `git flow release finish -m "v1.2.0" v1.2.0`   | Merge into `main`, tag `v1.2.0`, merge back into `develop`                   |
| hotfix  | start   | `git flow hotfix start v1.2.1`                 | Urgent fix from `main`                                                       |
| hotfix  | finish  | `git flow hotfix finish -m "v1.2.1" v1.2.1`    | Merge into `main` and `develop`, tag it                                      |
| push    | push    | `git push origin main develop v1.2.0`          | Send the branches and the tag after a release                                |

## Good to know

* `git flow ... finish` refuses a dirty working tree: commit or stash first.
* A feature with a single commit is fast-forwarded: no merge commit.
* A release finish checks out `main`: files that are ignored here but tracked on `main` are replaced by the tracked version (keep a copy of local secrets).
* Commit messages: gitmoji (`:sparkles:` feature, `:bug:` fix, `:books:` docs, `:white_check_mark:` tests, `:bookmark:` version).
