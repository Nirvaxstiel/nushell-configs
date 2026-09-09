source ../lib/cmd.nu
source ../.common.nu
source ../hermes/spec.nu
source ../tests/harness.nu

let hermes_spec_test = [
    { name: "build-hermes auto-profile returns Hermes args", run: {
        let args = (build-hermes --profile)
        assert-equal $args [-p $"nushell-(pwd | path expand | hash md5 | str substring 0..4)" chat]
    } }
    { name: "build-hermes dashboard --insecure", run: {
        let args = (build-hermes "dashboard" [] --insecure)
        assert-equal $args [dashboard -host 0.0.0.0 --insecure]
    } }
    { name: "build-docker dashboard", run: {
        let args = (build-docker docker --dashboard)
        assert-equal $args [
            docker run --rm -it
            -v $"(home-dir)/.hermes:/opt/data"
            -v $"($env.PWD | path expand):/home/user/projects/nushell"
            -w /home/user/projects/
            -p 9119:9119 -p 8642:8642 -e GATEWAY_HEALTH_URL=https://127.0.0.1:8642
            hermes-dev
        ]
    } }
    { name: "build-docker no dashboard", run: {
        let args = (build-docker docker)
        assert-equal $args [
            docker run --rm -it
            -v $"(home-dir)/.hermes:/opt/data"
            -v $"($env.PWD | path expand):/home/user/projects/nushell"
            -w /home/user/projects/
            hermes-dev
        ]
    } }
    { name: "docker and Hermes builders compose", run: {
        let docker_args = (build-docker docker --dashboard)
        let hermes_args = (build-hermes "dashboard" [] --insecure)
        let args = (build $docker_args $hermes_args)
        assert-equal ($args | last 4) [dashboard -host 0.0.0.0 --insecure]
        assert-equal ($args | first 2) [docker run]
    } }
    { name: "build-hermes no command", run: {
        let args = (build-hermes)
        assert-true (not ($args | any { |a| $a == "dashboard" }))
    } }
    { name: "build-hermes -p chat injects profile fallback", run: {
        let args = (build-hermes "chat" [] --profile)
        assert-equal ($args | last 3) [-p $"nushell-(pwd | path expand | hash md5 | str substring 0..4)" chat]
    } }
    { name: "build-hermes ignores profile subcommands outside profile command", run: {
        assert-equal (build-hermes "chat" [use]) [chat use]
    } }
    { name: "build-hermes doctor --fix", run: {
        assert-equal (build-hermes "doctor" [] --fix | last 1) [--fix]
    } }
    { name: "build-hermes profile use sets profile slug", run: {
        let args = (build-hermes "profile" [use])
        assert-true ($args | any { |a| $a == (path-slug 4) })
        assert-true (not ($args | any { |a| $a == "--needs_dirname" }))
    } }
    { name: "build-hermes profile list sets profile slug", run: {
        let args = (build-hermes "profile" [list])
        assert-true ($args | any { |a| $a == (path-slug 4) })
        assert-true (not ($args | any { |a| $a == "--needs_dirname" }))
    } }
    { name: "build-hermes profile clone sets flag", run: {
        let args = (build-hermes "profile" [list] --clone)
        assert-true ($args | any { |a| $a == "--clone" })
    } }
    { name: "panic-spec no command", run: {
        let spec = (panic-spec docker)
        assert-equal $spec [
            docker run --rm -it -v $"(home-dir)/.hermes:/opt/data" nousresearch/hermes-agent
        ]
    } }
    { name: "panic-spec omits empty command", run: {
        assert-equal (panic-spec docker "") (panic-spec docker)
    } }
    { name: "panic-spec preserves engine", run: {
        let args = (panic-spec podman)
        assert-equal ($args | first 2) [podman run]
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
