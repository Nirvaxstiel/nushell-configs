source ../.common.nu

def build-hermes [
    command?: string
    extra_args: list<string> = []
    --profile (-p)
    --insecure
    --tui
    --fix
    --resume (-r): string
    --clone
    --clone-all
] {
    let profile_cmds = [use create delete show alias rename export import list]
    let needs_profile_slug = ($command == "profile" and ($extra_args | any { |s| $s in $profile_cmds }))
    let slug = if ($profile or $needs_profile_slug) {
        path-slug 4
    } else {
        ""
    }

    let command_prefix = match $command {
        "dashboard" => [dashboard -host 0.0.0.0]
        null => []
        _ => [$command]
    }
    let base_args = (build $command_prefix $extra_args)

    let hermes_args = flag $base_args $insecure "--insecure"
    let hermes_args = flag $hermes_args $fix "--fix"
    let hermes_args = flag $hermes_args $needs_profile_slug $slug
    let hermes_args = flag $hermes_args $clone "--clone"
    let hermes_args = flag $hermes_args $clone_all "--clone-all"

    let chat_fallback = if ($profile and $command != "profile") {
        ["-p" $slug "chat"]
    } else {
        []
    }
    let tui_args = flag [] $tui "--tui"
    let flags = opt $tui_args $resume "--resume"

    build $hermes_args $chat_fallback $flags
}

def build-docker [
    engine: string
    --dashboard
] {
    let host_cwd = (pwd | path expand)
    let dirname = ($host_cwd | path basename)

    let data_vol = [-v $"(home-dir)/.hermes:/opt/data"]
    let project_vol = [-v $"($host_cwd):/home/user/projects/($dirname)"]
    let workdir = [-w /home/user/projects/]
    let dashboard_args = if $dashboard {
        [-p 9119:9119 -p 8642:8642 -e GATEWAY_HEALTH_URL=https://127.0.0.1:8642]
    } else {
        []
    }

    build [$engine run --rm -it] $data_vol $project_vol $workdir $dashboard_args [hermes-dev]
}

def panic-spec [
    engine: string
    command?: string
    --fix
    --tui
] {
    let data_vol = [-v $"(home-dir)/.hermes:/opt/data"]
    let base = (build [$engine run --rm -it] $data_vol [nousresearch/hermes-agent])
    let with_cmd = (flag $base ($command | is-not-empty) ($command | default ""))
    let p0 = flag $with_cmd $fix "--fix"
    flag $p0 $tui "--tui"
}

def build-spec [
    engine: string
    --pull
    --no-prune
] {
    let dockerfile_path = $nu.data-dir | path join "hermes"
    let build_cmd = (build (flag [$engine build] $pull "--pull") [-t hermes-dev $dockerfile_path])

    let builder_filters = if $engine == "docker" {[--filter type!=exec.cachemount]}
    let prune_cmd = if $no_prune { [] } else { [$engine builder prune -f ...$builder_filters] }
    { build: $build_cmd, prune: $prune_cmd }
}
