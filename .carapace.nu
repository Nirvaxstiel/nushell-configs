def carapace-specs-dir [] {
    let base = (if ($env.APPDATA? | is-empty) { ($nu.home-dir | path join ".config") } else { $env.APPDATA })
    ($base | path join "carapace" "specs")
}

def carapace-spec-path [name: string] {
    (carapace-specs-dir) | path join $"($name).yaml"
}

def carapace-spec-walker [] {
    ($nu.default-config-dir | path join "carapace" "argparse_spec.py")
}

def argparse-spec [python: string, target: string] {
    ^$python (carapace-spec-walker) $target | from json
}

def carapace-spec-write [spec: record] {
    mkdir (carapace-specs-dir) | ignore
    $spec | to yaml | save --force --raw (carapace-spec-path $spec.name) | ignore
    let nested = ($spec.commands | each { |c| $c.commands | length } | math sum)
    print $"($spec.name).yaml: ($spec.commands | length) commands, ($nested) subcommands"
}
