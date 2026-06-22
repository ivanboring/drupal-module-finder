# drupal-module-finder

A small command-line client (and agent skill) for the **Module Finder** API.
Find the right Drupal contributed module by describing the problem you need to
solve, inspect a module's details, and get the composer command to install it.
All output is raw Markdown.

## Layout

```
skills/drupal-module-finder/
  drupal-module-finder   # the CLI (self-contained bash, needs curl + jq)
  SKILL.md               # the agent skill document
  test-completion.sh     # tests for the bash completion
```

## Usage

```bash
cd skills/drupal-module-finder

./drupal-module-finder semantic-search "send private messages between users"
./drupal-module-finder module-info privatemsg
./drupal-module-finder module-info privatemsg --fields=stars,project_usage
./drupal-module-finder release-info privatemsg
./drupal-module-finder --help
```

Point at a different site with `--host=<url>` (default:
`http://module-finder.ddev.site`). Successful module lookups are cached for 14
days under `~/.cache/drupal-module-finder/`; override the location with
`DRUPAL_MODULE_FINDER_CACHE`.

## Shell completion (bash)

Completes subcommands, options, `--fields=` values, `--agent=` values, and any
module data names you have already cached:

```bash
source <(drupal-module-finder completion bash)
```

Add that line to your `~/.bashrc` to make it permanent. Completion registers for
the `drupal-module-finder` name on your `PATH` (the `./drupal-module-finder`
form does not auto-complete).

## Install as an agent skill

`SKILL.md` is the source of truth for the skill text. `install-skill` bundles a
copy of the command alongside it into a skills directory:

```bash
./drupal-module-finder install-skill --agent=claude   # -> .claude/skills/drupal-module-finder
./drupal-module-finder install-skill                  # -> .agents/skills/drupal-module-finder
```

## Tests

```bash
bash skills/drupal-module-finder/test-completion.sh
```

No network or Drupal needed — the completion tests run against a temporary cache.
