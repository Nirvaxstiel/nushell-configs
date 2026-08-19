source ../lib/cmd.nu
source ../.common.nu
source ../hermes/spec.nu
source ../tests/harness.nu

# Known deterministic baseline (captured before refactor).
let hermes_spec_test = [
    { name: "dev-spec dashboard --insecure", run: {
        let spec = (dev-spec docker "dashboard" [] --insecure)
        assert-equal $spec [
            docker run --rm -it
            -v $"($env.USERPROFILE)/.hermes:/opt/data"
            -v $"($env.PWD | path expand):/home/user/projects/nushell"
            -w /home/user/projects/
            -p 9119:9119 -p 8642:8642 -e GATEWAY_HEALTH_URL=https://127.0.0.1:8642
            hermes-dev dashboard -host 0.0.0.0 --insecure
        ]
    } }
    { name: "dev-spec no command", run: {
        let spec = (dev-spec docker)
        assert-true ($spec | any { |a| $a == "hermes-dev" })
        assert-true (not ($spec | any { |a| $a == "dashboard" }))
    } }
    { name: "dev-spec -p chat injects profile fallback", run: {
        let spec = (dev-spec docker "chat" [] --profile)
        assert-equal ($spec | last 3) [-p $"nushell-(pwd | path expand | hash md5 | str substring 0..4)" chat]
    } }
    { name: "dev-spec doctor --fix", run: {
        assert-equal (dev-spec docker "doctor" [] --fix | last 1) [--fix]
    } }
    { name: "dev-spec profile use sets needs_dirname", run: {
        let spec = (dev-spec docker "profile" [use])
        assert-true ($spec | any { |a| $a == "--needs_dirname" })
    } }
    { name: "dev-spec profile list does NOT set needs_dirname", run: {
        let spec = (dev-spec docker "profile" [list])
        assert-true (not ($spec | any { |a| $a == "--needs_dirname" }))
    } }
    { name: "dev-spec profile clone sets flag", run: {
        let spec = (dev-spec docker "profile" [list] --clone)
        assert-true ($spec | any { |a| $a == "--clone" })
    } }
    { name: "panic-spec no command", run: {
        let spec = (panic-spec docker)
        assert-equal $spec [
            run --rm -it -v $"($env.USERPROFILE)/.hermes:/opt/data" nousresearch/hermes-agent
        ]
    } }
    { name: "panic-spec doctor --fix --tui", run: {
        let spec = (panic-spec docker "doctor" --fix --tui)
        assert-true ($spec | any { |a| $a == "--fix" })
        assert-true ($spec | any { |a| $a == "--tui" })
        assert-equal ($spec | last 3) [doctor --fix --tui]
    } }
    { name: "build-spec pull --no-prune", run: {
        let s = (build-spec docker --pull --no-prune)
        assert-equal $s.build [docker build --pull -t hermes-dev .]
        assert-true ($s.prune | is-empty)
    } }
    { name: "build-spec default includes prune", run: {
        let s = (build-spec docker)
        assert-equal $s.build [docker build -t hermes-dev .]
        assert-equal $s.prune [docker builder prune -f --filter type!=exec.cachemount]
    } }
]
