source ../hermes/container.nu
source ../tests/harness.nu

# get-container-engine: pure resolution from --podman or env.
let container_test = [
    { name: "podman flag wins", run: {
        assert-equal (get-container-engine --podman) podman
    } }
    { name: "env HERMES_CONTAINER_ENGINE honored", run: {
        let saved = ($env.HERMES_CONTAINER_ENGINE? | default "<none>")
        $env.HERMES_CONTAINER_ENGINE = "podman"
        assert-equal (get-container-engine) podman
        $env.HERMES_CONTAINER_ENGINE = "docker"
        assert-equal (get-container-engine) docker
        if $saved == "<none>" { hide-env --ignore-errors HERMES_CONTAINER_ENGINE } else { $env.HERMES_CONTAINER_ENGINE = $saved }
    } }
    { name: "defaults to docker when unset", run: {
        let saved = ($env.HERMES_CONTAINER_ENGINE? | default "<none>")
        hide-env --ignore-errors HERMES_CONTAINER_ENGINE
        assert-equal (get-container-engine) docker
        if $saved == "<none>" { hide-env --ignore-errors HERMES_CONTAINER_ENGINE } else { $env.HERMES_CONTAINER_ENGINE = $saved }
    } }
    { name: "defaults to docker when null", run: {
        let saved = ($env.HERMES_CONTAINER_ENGINE? | default "<none>")
        $env.HERMES_CONTAINER_ENGINE = null
        assert-equal (get-container-engine) docker
        if $saved == "<none>" { hide-env --ignore-errors HERMES_CONTAINER_ENGINE } else { $env.HERMES_CONTAINER_ENGINE = $saved }
    } }
]
