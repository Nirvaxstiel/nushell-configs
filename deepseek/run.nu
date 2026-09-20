const DSH_DEFAULT_COMMIT = "ddefc45fbc7f8e46dd73185e68295696d1297887"

def dsh-image [] {
    "dsh-sandbox"
}

def dsh-port [] {
    3080
}

def dsh-build-args [--latest] {
    [
        "build"
        "--build-arg"
        $"DSH_COMMIT=(dsh-commit --latest=$latest)"
        "-t"
        (dsh-image)
        "."
    ]
}


def dsh-run-args [] {
    [
        "run"
        "--rm"
        "-it"
        "--name" "dsh"
        "-p" $"127.0.0.1:(dsh-port):3081"
        "-v" $"($env.PWD):/workspace:Z"
        "-w" "/workspace"
        "-e" "DEEPSEEK_API_KEY"
        (dsh-image)
    ]
}

def dsh-build [--latest] {
    ^podman ...(dsh-build-args --latest=$latest)
}

def dsh-run [] {
    podman ...(dsh-run-args)
}

def dsh [--latest] {
    dsh-build --latest=$latest
    dsh-run
}

def dsh-repo [] {
    "https://github.com/deepseek-ai/deepseek-harness.git"
}

def valid-dsh-commit [commit: string] {
    ($commit | str length) == 40 and (($commit | str replace -r -a '[0-9a-fA-F]' '') | is-empty)
}

def dsh-commit [--latest] {
    let pinned_commit = ($env.DSH_COMMIT? | default "")
    let commit = if ($pinned_commit | is-not-empty) {
        $pinned_commit
    } else if $latest {
        ^git ls-remote (dsh-repo) refs/heads/master
        | lines
        | first
        | split row "\t"
        | first
    } else {
        $DSH_DEFAULT_COMMIT
    }
    if not (valid-dsh-commit $commit) {
        error make { msg: "DSH_COMMIT must be a 40-character hexadecimal commit" }
    }
    $commit
}
