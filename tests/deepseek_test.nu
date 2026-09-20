source ../deepseek/run.nu
source ../tests/harness.nu

let deepseek_test = [
    { name: "dsh default commit is pinned", run: {
        let saved = ($env.DSH_COMMIT? | default "<none>")
        hide-env --ignore-errors DSH_COMMIT
        let commit = (dsh-commit)
        assert-equal ($commit | str length) 40
        assert-true (($commit | str replace -r -a '[0-9a-fA-F]' '') | is-empty)
        if $saved == "<none>" { hide-env --ignore-errors DSH_COMMIT } else { $env.DSH_COMMIT = $saved }
    } }
    { name: "dsh-commit honors pinned environment value", run: {
        let saved = ($env.DSH_COMMIT? | default "<none>")
        let pinned_commit = "0123456789abcdef0123456789abcdef01234567"
        $env.DSH_COMMIT = $pinned_commit
        assert-equal (dsh-commit) $pinned_commit
        assert-true ((dsh-build-args | get 2) == $"DSH_COMMIT=($pinned_commit)")
        if $saved == "<none>" { hide-env --ignore-errors DSH_COMMIT } else { $env.DSH_COMMIT = $saved }
    } }
    { name: "dsh-run args keep host port local", run: {
        let loopback = ([127 0 0 1] | str join ".")
        let args = (dsh-run-args)
        assert-equal ($args | first 5) [run --rm -it --name dsh]
        assert-equal ($args | get 6) $"($loopback):3080:3081"
    } }
    { name: "dsh-commit rejects non-sha values", run: {
        let saved = ($env.DSH_COMMIT? | default "<none>")
        $env.DSH_COMMIT = "bad"
        let message = (try { dsh-commit } catch { |e| $e.msg })
        assert-equal $message "DSH_COMMIT must be a 40-character hexadecimal commit"
        if $saved == "<none>" { hide-env --ignore-errors DSH_COMMIT } else { $env.DSH_COMMIT = $saved }
    } }
]
