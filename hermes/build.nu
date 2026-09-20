source ($nu.default-config-dir | path join ".common.nu")
source ($nu.default-config-dir | path join "hermes" "container.nu")
source ($nu.default-config-dir | path join "hermes" "spec.nu")

def hermes-build [
    --pull
    --dry-run
    --no-prune
    --podman
] {
    let engine = (get-container-engine --podman=$podman)
    let specs = (build-spec $engine --pull=$pull --no-prune=$no_prune)

    bind (_run-or-dry-run $specs.build $dry_run) { |build_cmd|
        if ($specs.prune | is-empty) {
            ok $build_cmd
        } else {
            _run-or-dry-run $specs.prune $dry_run
        }
    }
}
