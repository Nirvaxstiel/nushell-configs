source ($nu.default-config-dir | path join "lib" "result.nu")

const CORE_PLUGINS = [gstat inc polars formats query]

def plugin-exe-path [dir: string, plugin: string] {
    $dir | path join $"nu_plugin_($plugin).exe"
}

def usable-plugin [dir: string, plugin: string, entry: record] {
    let exe = (plugin-exe-path $dir $plugin | path expand)
    let recorded = ($entry.filename? | default "")
    let status = ($entry.status? | default "")
    (($status == "loaded") or ($status == "running")) and ($recorded | path expand) == $exe and ($recorded | path exists)
}

def unloaded-plugins [dir: string, entries: list<record>] {
    $CORE_PLUGINS | where { |plugin| ($entries | where { |entry| usable-plugin $dir $plugin $entry } | is-empty) }
}

def absent-binaries [dir: string] {
    $CORE_PLUGINS | where { |plugin| not ((plugin-exe-path $dir $plugin) | path exists) }
}

def add-plugin [dir: string, plugin: string] {
    try {
        plugin add (plugin-exe-path $dir $plugin)
        ok $plugin
    } catch { |e|
        err { plugin: $plugin, kind: "add-failed", msg: $e.msg }
    }
}

def bootstrap-core-plugins [dir: string] {
    let entries = (try { plugin list } catch { [] })
    let absent = (absent-binaries $dir)
    unloaded-plugins $dir $entries | each { |plugin|
        if $plugin in $absent {
            err { plugin: $plugin, kind: "binary-absent", msg: "binary missing from the nu directory" }
        } else {
            add-plugin $dir $plugin
        }
    }
}

def nu-bootstrap-core-plugins [] {
    if ($nu.plugin-path | is-empty) { return }
    let results = (bootstrap-core-plugins ($nu.current-exe | path dirname | path expand))
    let registered = ($results | where { |r| result-is-ok $r } | get value)
    if ($registered | is-not-empty) {
        print $"registered core plugins: ($registered | str join ', '); restart Nushell to load them"
    }
    let failures = ($results | where { |r| result-is-err $r })
    for failure in $failures {
        print $"($failure.error.plugin): ($failure.error.msg)"
    }
}
