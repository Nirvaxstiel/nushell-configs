def dsh-image [] {
    "dsh-sandbox"
}

def dsh-port [] {
    3080
}

def dsh-build-args [] {
    [
        "build"
        "--build-arg"
        $"DSH_COMMIT=(dsh-commit)"
        "-t"
        "dsh-sandbox"
        "."
    ]
}


def dsh-run-args [] {
    [
        "run"
        "--rm"
        "-it"
        "--name" "dsh"
        "-p" $"127.0.0.1:3080:3081"
        "-v" $"($env.PWD):/workspace:Z"
        "-w" "/workspace"
        "-e" "DEEPSEEK_API_KEY"
        (dsh-image)
    ]
}

def dsh-build [] {
    ^podman ...(dsh-build-args)
}

def dsh-run [] {
    podman ...(dsh-run-args)
}

def dsh [] {
    dsh-build
    dsh-run
}

def dsh-repo [] {
    "https://github.com/deepseek-ai/deepseek-harness.git"
}

def dsh-commit [] {
    ^git ls-remote (dsh-repo) refs/heads/master
    | lines
    | first
    | split row "\t"
    | first
}
