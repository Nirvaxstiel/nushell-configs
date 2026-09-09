source ../tests/harness.nu
source ../.maid/init.nu

# get-targets: pure intersection of catalog with registry.
let maid_test = [
    { name: "intersects catalog with registry", run: {
        let catalog = [
            { name: npm category: package-manager clean: {||} prune: null update: null audit: null audit_fix: null }
            { name: hermes category: agent clean: {||} prune: null update: null audit: null audit_fix: null }
        ]
        let registry = [ { name: npm category: package-manager } { name: uv category: package-manager } ]
        let got = (get-targets $catalog $registry | get name)
        assert-equal $got [npm]
    } }
    { name: "empty registry yields empty", run: {
        let catalog = [ { name: npm clean: {||} } ]
        assert-true ((get-targets $catalog [] | is-empty))
    } }
    { name: "maid-action returns ok on success", run: {
        let t = { name: demo clean: {|| "cleaned" } }
        let r = (maid-action $t "clean")
        assert-is-ok $r
        assert-equal $r.val.target demo
    } }
    { name: "maid-action errs when action missing", run: {
        let t = { name: demo clean: null }
        let r = (maid-action $t "clean")
        assert-is-err $r
        assert-equal $r.err.kind "no-action"
    } }
    { name: "maid-action errs on exec failure", run: {
        let t = { name: boom clean: {|| ^false } }
        let r = (maid-action $t "clean")
        assert-is-err $r
        assert-equal $r.err.kind "exec-failed"
    } }
    { name: "maid-run handles action failure", run: {
        let t = { name: boom clean: {|| error make { msg: "boom" }} }
        maid-run boom clean [$t]
    } }
]
