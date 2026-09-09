source ../.common.nu
source ./container.nu
source ./spec.nu

def hermes-dev [
    command?: string
    ...extra_args: string
    --profile (-p)
    --dry-run
    --insecure
    --tui
    --fix
    --resume (-r): string
    --clone
    --clone-all
    --podman
    --baremetal
] {
    let hermes_args = (build-hermes $command $extra_args
        --profile=$profile --insecure=$insecure --tui=$tui --fix=$fix
        --resume=$resume --clone=$clone --clone-all=$clone_all)
    let prefix = match $baremetal {
        true => [hermes]
        false => {
            let engine = (get-container-engine --podman=$podman)
            build-docker $engine --dashboard=($command == "dashboard")
        }
    }
    let spec = (build $prefix $hermes_args)
    bind (_run-or-dry-run $spec $dry_run) { |_| null }
}

def hermes-panic [
    command?: string
    --fix
    --tui
    --podman
] {
    let engine = (get-container-engine --podman=$podman)
    let spec = (panic-spec $engine $command --fix=$fix --tui=$tui)
    let res = (_run-or-dry-run $spec false)
    if (result-is-err $res) {
        error make { msg: $"hermes-panic failed: ($res.err.msg)" }
    }
}
