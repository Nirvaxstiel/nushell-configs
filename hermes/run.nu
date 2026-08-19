source ../.common.nu
source ./container.nu
source ../lib/result.nu
source ../lib/cmd.nu
source ./spec.nu

# Interactive hermes-dev session. Pure spec is built, then executed.
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
] {
    let engine = (get-container-engine --podman)
    let spec = (dev-spec $engine $command $extra_args
        --profile=$profile --insecure=$insecure --tui=$tui --fix=$fix
        --resume=$resume --clone=$clone --clone-all=$clone_all)
    _run-or-dry-run $spec $dry_run | ignore
}

# Run the published hermes-agent image directly.
def hermes-panic [
    command?: string
    --fix
    --tui
    --podman
] {
    let engine = (get-container-engine --podman)
    let spec = (panic-spec $engine $command --fix=$fix --tui=$tui)
    let res = (_run-or-dry-run $spec false)
    if (result-is-err $res) {
        error make { msg: $"hermes-panic failed: ($res.err.msg)" }
    }
}
