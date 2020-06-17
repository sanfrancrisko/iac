# Github PR File Modification Query
## Setup
- Run `bundle install`
- Set the `INTERESTED_FILE` variable to the filepath you're interested in determining was changed in a PR. E.g.
```
# Matches on '.github/workflows/release.yml' and '.github/workflows/weekly.yml'
INTERESTED_FILE='.github/workflows'
# Matches on 'Gemfile' in root dir
INTERESTED_FILE='Gemfile'
```
- Set your Github API Token to the ENV VAR `GITHUB_TOKEN`
- Run:
```
GITHUB_TOKEN=abcdefghij123456789 bundle exec ruby gh_pr_query.rb
```

## Notes
- Currently queries all repos from [here](https://puppetlabs.github.io/iac/modules.json). You can modify / parameterize the `repos` var to achieve what you want.
- Outputs to a file with a list of all PRs you need to inspect, with the name format: `YYYY_MM_DD_HH_MM_SS_$REPO_NAME`
- Also outputs a load of stuff about what it's doing to the screen - still a rough draft
- This can be improved