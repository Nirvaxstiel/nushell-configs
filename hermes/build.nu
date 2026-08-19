source ../.common.nu
source ./container.nu
source ../lib/result.nu
source ../lib/cmd.nu
source ./spec.nu

def hermes-build [
    --pull
    --dry-run
    --no-prune
    --podman
] {
    let engine = (get-container-engine --podman)
    let specs = (build-spec $engine --pull=$pull --no-prune=$no_prune)

    let r1 = (_run-or-dry-run $specs.build $dry_run)
    if (result-is-err $r1) { return $r1 }

    if ($specs.prune | is-empty) { return $r1 }

    _run-or-dry-run $specs.prune $dry_run | ignore
}
