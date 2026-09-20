source ($nu.default-config-dir | path join "lib" "result.nu")
source ($nu.default-config-dir | path join ".maid" "core.nu")

def maid [
    --clean(-c)
    --prune(-p)
    --update(-u)
    --audit(-e)
    --fix(-f)
    --all(-a)
    --list(-l)
    --probe(-r)
    target?: string
] {
    if $probe { maid-regen; return }

    let targets = (get-targets $MAID_CATALOG (read-registry))

    if $all and not $clean and not $prune {
        if ($targets | is-empty) { print "no tools registered. run maid -r"; return }
        maid-clean-all $targets
        maid-prune-all $targets
        return
    }

    if $list { maid-list $targets; return }

    if ($targets | is-empty) { print "no tools registered. run maid -r"; return }

    if $clean {
        if ($target | is-empty) { print "specify target or use -c -a"; return }
        if $all { maid-clean-all $targets; return }
        maid-run $target "clean" $targets
        return
    }

    if $prune {
        if ($target | is-empty) { print "specify target or use -p -a"; return }
        if $all { maid-prune-all $targets; return }
        maid-run $target "prune" $targets
        return
    }

    if $update {
        if ($target | is-empty) { print "specify target or use -u -a"; return }
        if $all { maid-update-all $targets; return }
        maid-update $target $targets
        return
    }

    if $audit {
        if ($target | is-empty) { print "specify target or use -e -a"; return }
        if $all { maid-audit-all $targets; return }
        let action = (if $fix { "audit_fix" } else { "audit" })
        maid-run $target $action $targets
        return
    }

    if $fix and not $audit { print "--fix requires --audit (-e)"; maid-help; return }

    maid-help
}

def maid-help [] {
    print "maid: clean up your dev environment"
    print ""
    print "  maid -l              list registered tools"
    print "  maid -c <name>       clean a tool"
    print "  maid -c -a           clean all"
    print "  maid -p <name>       prune a tool"
    print "  maid -p -a           prune all"
    print "  maid -u <name>       update + clean a tool"
    print "  maid -u -a           update + clean all"
    print "  maid -e <name>       audit a tool (security/vulns)"
    print "  maid -e <name> -f    audit + auto-fix vulnerabilities"
    print "  maid -e -a           audit all"
    print "  maid -a              clean + prune all"
    print ""
    print "  maid -r              regenerate registry"
}

def maid-regen [] {
    print "scanning for installed tools..."
    let found = ($MAID_CATALOG | where { |t| not ($t.detect | is-empty) } | where { |t| do $t.detect | is-not-empty })
    if ($found | is-empty) { print "(none found)"; return }
    print ""
    $found | group-by category | items { |cat, tools|
        print $"($cat): (($tools | get name | str join ', '))"
    }
    let count = ($found | length)
    print ""
    print $"($count) tools found"
    let names = ($found | each { |t| { name: $t.name, category: $t.category } })
    $names | to json | save -f $REGISTRY_FILE
    print "registry updated."
}

def maid-run [target: string, action: string, targets: list<record>] {
    let t = ($targets | where { |it| $it.name == $target } | first)
    if ($t == null) { print $"unknown target: ($target)"; return }
    let res = (maid-action $t $action)
    maid-report-failures [$res]
}

def maid-report-failures [results: list<record>] {
    let failures = ($results | where { |result| result-is-err $result })
    if ($failures | is-empty) { return }
    print "failures:"
    for result in $failures {
        let failure = $result.error
        let detail = ($failure.msg? | default $failure.kind)
        print $"  ($failure.target) ($failure.action): ($detail)"
    }
}

def maid-clean-all [targets: list<record>] {
    let to_clean = ($targets | where { |t| $t.clean? | is-not-empty })
    if ($to_clean | is-empty) { print "no clean targets"; return }
    print $"cleaning (($to_clean | length)) targets..."
    let results = ($to_clean | each { |t| maid-action $t "clean" })
    maid-report-failures $results
}

def maid-prune-all [targets: list<record>] {
    let to_prune = ($targets | where { |t| $t.prune? | is-not-empty })
    if ($to_prune | is-empty) { print "no prune targets"; return }
    print $"pruning (($to_prune | length)) targets..."
    let results = ($to_prune | each { |t| maid-action $t "prune" })
    maid-report-failures $results
}

def maid-update [target: string, targets: list<record>] {
    let t = ($targets | where { |it| $it.name == $target } | first)
    if ($t == null) { print $"unknown target: ($target)"; return }
    if not ($t.update? | is-not-empty) { print $"($t.name): no update command"; return }
    let update_result = (maid-action $t "update")
    if (result-is-err $update_result) {
        maid-report-failures [$update_result]
        return
    }
    if ($t.clean? | is-not-empty) {
        let clean_result = (maid-action $t "clean")
        maid-report-failures [$clean_result]
    }
}

def maid-update-all [targets: list<record>] {
    let to_update = ($targets | where { |t| $t.update? | is-not-empty })
    if ($to_update | is-empty) { print "no targets have update commands"; return }
    print $"updating (($to_update | length)) targets..."
    let results = ($to_update | each { |t|
        let update_result = (maid-action $t "update")
        if (result-is-err $update_result) {
            $update_result
        } else if ($t.clean? | is-not-empty) {
            maid-action $t "clean"
        } else {
            $update_result
        }
    })
    maid-report-failures $results
}

def maid-audit-all [targets: list<record>] {
    let to_audit = ($targets | where { |t| $t.audit? | is-not-empty })
    if ($to_audit | is-empty) { print "no targets have audit commands"; return }
    print $"auditing (($to_audit | length)) targets..."
    let results = ($to_audit | each { |t| maid-action $t "audit" })
    maid-report-failures $results
}

def maid-list [targets: list<record>] {
    let mtime = (try { (ls $REGISTRY_FILE | get 0).modified } catch { null })
    if $mtime != null {
        let age = ((date now) - $mtime)
        if $age > 30day {
            print $"registry: (($age | date humanize)) old -- may be stale. maid -r to regenerate"
        }
    }
    print ""
    print "actions: c (clean)  p (prune)  u (update)  e (audit)  a (clean+prune all)"
    print ""
    let clean_targets = ($targets | where { |t| $t.clean? | is-not-empty })
    let prune_targets = ($targets | where { |t| $t.prune? | is-not-empty })
    let audit_targets = ($targets | where { |t| $t.audit? | is-not-empty })

    if ($clean_targets | is-not-empty) {
        print "clean targets:"
        $clean_targets | get name | each { |n| print $"  ($n)" }
    }
    if ($prune_targets | is-not-empty) {
        print "prune targets:"
        $prune_targets | get name | each { |n| print $"  ($n)" }
    }
    if ($audit_targets | is-not-empty) {
        print "audit targets:"
        $audit_targets | get name | each { |n| print $"  ($n)" }
    }
}
