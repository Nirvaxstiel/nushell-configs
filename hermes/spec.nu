source ../.common.nu
source ../lib/cmd.nu

def dev-spec [
    engine: string
    command?: string
    extra_args: list<string> = []
    --profile (-p)
    --insecure
    --tui
    --fix
    --resume (-r): string
    --clone
    --clone-all
    --podman
] {
    let host_cwd = (pwd | path expand)
    let dirname = ($host_cwd | path basename)
    let slug = (path-slug 4)

    let DATA_VOL = [-v $"($env.USERPROFILE)/.hermes:/opt/data"]
    let PROJECT_VOL = [-v $"($host_cwd):/home/user/projects/($dirname)"]
    let WORKDIR = [-w /home/user/projects/]

    let dash_ports = if $command == "dashboard" {
        [-p 9119:9119 -p 8642:8642 -e GATEWAY_HEALTH_URL=https://127.0.0.1:8642]
    } else { [] }

    let PROFILE_CMDS = [use create delete show alias rename export import]
    let needs_dirname = ($extra_args | any { |s| $s in $PROFILE_CMDS })

    let base_args = match $command {
        "dashboard" => (["dashboard" "-host" "0.0.0.0"] | append $extra_args)
        "doctor" => (["doctor"] | append $extra_args)
        "profile" => (["profile"] | append $extra_args)
        null => $extra_args
        _ => ([$command] | append $extra_args)
    }

    let ha = flag $base_args $insecure "--insecure"
    let ha = flag $ha $fix "--fix"
    let ha = flag $ha $needs_dirname "--needs_dirname"
    let ha = flag $ha $clone "--clone"
    let hermes_args = flag $ha $clone_all "--clone-all"

    let chat_fallback = if ($profile and $command != "profile") { ["hermes" "-p" $slug "chat"] } else { [] }
    let f0 = flag [] $tui "--tui"
    let flags = opt $f0 $resume "--resume"

    [$engine run --rm -it]
        | append $DATA_VOL
        | append $PROJECT_VOL
        | append $WORKDIR
        | append $dash_ports
        | append [hermes-dev]
        | append $hermes_args
        | append $chat_fallback
        | append $flags
        | flatten
}

def panic-spec [
    engine: string
    command?: string
    --fix
    --tui
    --podman
] {
    let data_vol = [-v $"($env.USERPROFILE)/.hermes:/opt/data"]
    let base = ([run --rm -it] | append $data_vol | append [nousresearch/hermes-agent])
    let with_cmd = if ($command | is-not-empty) { $base | append $command } else { $base }
    let p0 = flag $with_cmd $fix "--fix"
    flag $p0 $tui "--tui"
}

def build-spec [
    engine: string
    --pull
    --no-prune
    --podman
] {
    let b0 = flag [$engine build] $pull "--pull"
    let build_cmd = ($b0 | append [-t hermes-dev .] | flatten)
    let prune_cmd = if $no_prune { [] } else { [$engine builder prune -f --filter type!=exec.cachemount] }
    { build: $build_cmd, prune: $prune_cmd }
}
