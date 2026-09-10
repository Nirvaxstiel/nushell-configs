source ../lib/result.nu

const MAID_DIR = ($nu.default-config-dir | path join ".maid")
source ($MAID_DIR | path join "catalog.nu")

const REGISTRY_FILE = ($MAID_DIR | path join "registry.json")

def read-registry [] {
    try { open $REGISTRY_FILE } catch { [] }
}

def get-targets [catalog: list<record>, registry: list<record>] {
    let names = ($registry | each { |r| $r.name })
    $catalog | where { |t| $names | any { |n| $n == $t.name } }
}

def maid-action [target: record, action: string] {
    let action_fn = ($target | get $action)
    if ($action_fn | is-empty) {
        return (err { kind: "no-action", target: $target.name, action: $action })
    }
    print $"($target.name): ($action)"
    let lines = try { do $action_fn } catch { |e|
        return (err { kind: "exec-failed", target: $target.name, action: $action, msg: $e.msg, exit_code: ($e | get exit_code?) })
    }
    if ($lines | is-not-empty) { $lines | each { |line| print $line } }
    ok { target: $target.name, action: $action }
}
