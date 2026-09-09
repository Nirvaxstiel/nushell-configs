def dsh-image [] {
    "dsh-sandbox"
}

def dsh-port [] {
    3080
}

def dsh-build-args [] {
    [
        "build"
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
        "-p" $"127.0.0.1:3080:3081"
        "-v" $"($env.PWD):/workspace:Z"
        "-w" "/workspace"
        "-e" "DEEPSEEK_API_KEY"
        (dsh-image)
    ]
}

def podman [args: list<string>] {
    ^podman ...$args
}

def dsh-build [] {
    podman (dsh-build-args)
}

def dsh-run [] {
    podman (dsh-run-args)
}

def dsh [] {
    dsh-build
    dsh-run
}
