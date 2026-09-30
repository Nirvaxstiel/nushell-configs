source ../.carapace.nu
source ../tests/harness.nu

let flags_help = r#'usage: tool [-h] [--quiet]

options:
  -h, --help            show this help message and exit
  -q, --query QUERY     Query to run. On a real TTY the prompt seeds an
                        interactive session (submitted literally as the
                        first turn)
  --oneshot             Answer the query and exit
'#

let commands_braces = r#'usage: tool {alpha,beta,gamma} ...

positional arguments:
  {alpha,beta,gamma}
    alpha         First thing
    beta          Second thing
    gamma         Third thing

options:
  -h, --help  show this help message and exit
'#

let commands_metavar = r#'usage: tool COMMAND ...

positional arguments:
  COMMAND
    status        Show status
    prune         Delete stale entries

options:
  -h, --help  show this help message and exit
'#

let commands_plain = r#'usage: tool [message] ...

positional arguments:
  message               Message text. If omitted, read from stdin.

options:
  -h, --help  show this help message and exit
'#

let carapace_spec_test = [
    { name: "argparse-section stops before the next unindented header", run: {
        let section = (argparse-section $commands_braces "positional arguments:")
        assert-true (($section | first | str trim) == "{alpha,beta,gamma}")
        assert-true (not ($section | any { |l| $l | str starts-with "options:" }))
    } }
    { name: "argparse-flags joins wrapped descriptions and keeps first lines", run: {
        let flags = (argparse-flags (argparse-entries (argparse-section $flags_help "options:")))
        assert-true ($flags.'-q'.description | str contains "Query to run")
        assert-true ($flags.'-q'.description | str contains "first turn")
        assert-true ($flags.'--query'.description | str contains "interactive session")
    } }
    { name: "argparse-flags marks value-taking flags with nargs and leaves switches bare", run: {
        let flags = (argparse-flags (argparse-entries (argparse-section $flags_help "options:")))
        assert-equal $flags.'--query'.nargs 1
        assert-equal $flags.'-q'.nargs 1
        assert-equal ($flags.'--oneshot' | columns) [description]
        assert-equal $flags.'-h'.description "show this help message and exit"
    } }
    { name: "argparse-commands reads brace groups", run: {
        let names = (argparse-commands (argparse-entries (argparse-section $commands_braces "positional arguments:")) | get name)
        assert-equal $names [alpha beta gamma]
    } }
    { name: "argparse-commands reads uppercase metavar groups", run: {
        let parsed = (argparse-commands (argparse-entries (argparse-section $commands_metavar "positional arguments:")))
        assert-equal ($parsed | get name) [status prune]
        assert-equal ($parsed | first | get description) "Show status"
    } }
    { name: "argparse-commands ignores plain positional arguments", run: {
        assert-equal (argparse-commands (argparse-entries (argparse-section $commands_plain "positional arguments:"))) []
    } }
    { name: "carapace-specs-dir targets the carapace specs directory", run: {
        assert-equal (carapace-specs-dir | path basename) "specs"
        assert-equal (carapace-specs-dir | path dirname | path basename) "carapace"
    } }
]
