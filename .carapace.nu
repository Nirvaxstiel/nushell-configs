def argparse-section [text: string, header: string] {
    let lines = ($text | lines)
    let idx = ($lines | enumerate | where { |e| ($e.item | str trim) == $header } | get 0?.index?)
    if $idx == null { return [] }
    $lines | skip ($idx + 1) | take while { |l| not ((($l | str trim) == $l) and ($l | is-not-empty)) }
}

def argparse-entries [section: list<string>] {
    $section | reduce --fold [] { |line, acc|
        let lead = (($line | str length) - ($line | str trim --left | str length))
        let head = ($line | parse --regex '^\s{2,4}(?<head>\S.*)$')
        if ($head | is-not-empty) and ($lead <= 4) {
            $acc | append { head: ($head | get 0.head | str trim), desc: "", lead: $lead }
        } else if ($acc | is-empty) {
            $acc
        } else {
            let last = ($acc | last)
            $acc | drop 1 | append ($last | update desc ($"($last.desc) ($line | str trim)" | str trim))
        }
    }
}

def argparse-parts [head: string] {
    let parts = ($head | split row --regex '\s{2,}')
    {
        names: ($parts | first)
        desc: (if ($parts | length) > 1 { $parts | skip 1 | str join " " } else { "" })
    }
}

def argparse-group [entry: record] {
    let head = ($entry.head | str trim)
    ($entry.lead <= 4) and ([
        ($head | str starts-with '{')
        ($head | str starts-with '<')
        (($head | str uppercase) == $head)
    ] | any { |ok| $ok })
}

def argparse-flags [entries: list<record>] {
    $entries
    | where { |e| ($e.head | str starts-with '-') }
    | each { |e|
        let p = (argparse-parts $e.head)
        let desc = ([$p.desc $e.desc] | where { |s| $s != "" } | str join " ")
        let names = ($p.names | split row ', ')
        let takes_value = ($names | any { |n| (($n | str trim | split row ' ') | length) > 1 })
        let base = (if $desc == "" { {} } else { { description: $desc } })
        let value = (if $takes_value { $base | upsert nargs 1 } else { $base })
        $names | each { |name| { flag: ($name | str trim | split row ' ' | first), value: $value } }
    }
    | flatten
    | reduce --fold {} { |it, acc| $acc | upsert $it.flag $it.value }
}

def argparse-commands [entries: list<record>] {
    let idx = ($entries | enumerate | where { |e| argparse-group $e.item } | get 0?.index?)
    if $idx == null { return [] }
    let group = ($entries | get $idx)
    $entries
    | skip ($idx + 1)
    | take while { |e| $e.lead > $group.lead }
    | each { |e| (argparse-parts $e.head) | insert cont $e.desc }
    | where { |e| $e.names =~ '^[a-z0-9][a-z0-9-]*$' }
    | each { |e| { name: $e.names, description: ([$e.desc $e.cont] | where { |s| $s != "" } | str join " ") } }
}

def argparse-spec-command [exe: string, path: list<string>, description: string] {
    let help = (^$exe ...$path --help)
    {
        name: ($path | last)
        description: $description
        flags: (argparse-flags (argparse-entries (argparse-section $help "options:")))
        commands: (argparse-commands (argparse-entries (argparse-section $help "positional arguments:")))
    }
}

def argparse-spec [exe: string] {
    let help = (^$exe --help)
    let description = ($help | lines | where { |l| ($l | str trim) == $l and ($l | is-not-empty) and (not ($l | str starts-with 'usage:')) } | first)
    let top = (argparse-commands (argparse-entries (argparse-section $help "positional arguments:")))
    let built = ($top | par-each { |c| argparse-spec-command $exe [$c.name] $c.description })
    let grandchildren = ($built
        | each { |c| $c.commands | each { |g| { parent: $c.name, name: $g.name, description: $g.description } } }
        | flatten)
    let built_deep = ($grandchildren | par-each { |g| { parent: $g.parent, record: (argparse-spec-command $exe [$g.parent $g.name] $g.description) } })
    {
        name: $exe
        description: $description
        flags: (argparse-flags (argparse-entries (argparse-section $help "options:")))
        commands: ($built | each { |c|
            let kids = ($built_deep | where { |g| $g.parent == $c.name } | get record)
            if ($kids | is-empty) { $c } else { $c | upsert commands $kids }
        })
    }
}

def carapace-specs-dir [] {
    let base = (if ($env.APPDATA? | is-empty) { ($nu.home-dir | path join ".config") } else { $env.APPDATA })
    ($base | path join "carapace" "specs")
}

def carapace-spec-path [name: string] {
    (carapace-specs-dir) | path join $"($name).yaml"
}

def carapace-spec-write [spec: record] {
    mkdir (carapace-specs-dir) | ignore
    $spec | to yaml | save --force --raw (carapace-spec-path $spec.name) | ignore
    let nested = ($spec.commands | each { |c| $c.commands | length } | math sum)
    print $"($spec.name).yaml: ($spec.commands | length) commands, ($nested) subcommands"
}
