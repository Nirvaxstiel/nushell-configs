# Hermes Agent Setup

## Structure

```
nushell/
├── lib/
│   ├── result.nu      # Result monad: ok/err/map/bind/is-ok/is-err/unwrap-or
│   └── cmd.nu         # Pure docker-arg builders: flag/opt/args/build
├── tests/
│   ├── run.nu         # TAP-ish runner: `nu tests/run.nu`
│   ├── harness.nu     # assert-equal/assert-true/assert-is-ok/assert-is-err
│   ├── result_test.nu
│   ├── cmd_test.nu
│   ├── container_test.nu
│   ├── hermes_spec_test.nu
│   └── maid_test.nu
├── .common.nu         # Shared utils: path-slug, _run-or-dry-run (-> Result)
├── .hermes-agent.nu   # Entry point: sources run.nu + build.nu
├── .maid/
│   ├── core.nu        # Pure: get-targets, read-registry, maid-action (-> Result)
│   ├── init.nu        # Command surface (maid, maid-regen, ...)
│   ├── catalog.nu     # known tools + commands
│   └── registry.json  # tools this machine has
└── hermes/
    ├── spec.nu        # PURE arg-vector builders: dev-spec/panic-spec/build-spec
    ├── run.nu         # hermes-dev, hermes-panic (spec -> _run-or-dry-run)
    ├── build.nu       # hermes-build
    ├── container.nu   # get-container-engine (pure)
    ├── Dockerfile
    └── README.md
```


## Quick Start

```nu
source .hermes-agent.nu

hermes-build --pull   # build docker image (run from nushell/ dir)
hermes-dev -p         # interactive chat with auto profile
hermes-dev --dry-run  # inspect command without running
```

## Shared Utils (.common.nu)

```nu
path-slug [len: int = 4]     # deterministic slug: "my-project-a1b2"
_run-or-dry-run [cmd, dry]   # print + exec, or dry-run
```

## hermes-dev

```nu
hermes-dev [command] [args...] [flags]
hermes-dev chat -q "summarize this"
hermes-dev profile list
hermes-dev dashboard
hermes-dev doctor --fix
```

## Flags

| Flag          | Short | Description                           |
|---------------|-------|---------------------------------------|
| `--profile`   | `-p`  | Auto-chat with `dirname-hash` profile |
| `--dry-run`   |       | Print command without executing        |
| `--insecure`  |       | Dashboard: skip TLS                   |
| `--tui`       |       | Use TUI mode                          |
| `--fix`       |       | Doctor: auto-fix issues               |
| `--resume`    | `-r`  | Resume session by name/ID             |
| `--clone`     |       | Profile: clone config from active     |
| `--clone-all` |       | Profile: clone all state              |

## Volume Mounts

| Host                   | Container                        | Purpose            |
|------------------------|----------------------------------|--------------------|
| `$USERPROFILE/.hermes` | `/opt/data`                      | Hermes data dir    |
| `$(pwd)/.hermes`       | `/home/user/projects/<dirname>`  | Per-project data   |
| `/home/user/projects/` | `-w`                            | Default workdir    |

## Profile Naming

`path-slug 4` → `my-project-a1b2`  
`path-slug` (default 4) uses md5 of full path — same name from anywhere in the tree, unique across different paths with identical dirname.

## Custom Image Additions

- .NET SDK 10.0 + ASP.NET 10.0/8.0 runtimes
- `roslyn-language-server` (dotnet tool)
- `graphify` (uv tool, hermes platform)

## Maid Cleanup

Registered in `.maid/catalog.nu` — run `maid -r` to pick them up.

```nu
maid -c -a              # clean + prune everything
maid -c docker          # prune dangling images, builder cache
maid -c hermes          # prune old sessions + checkpoints
maid -u hermes         # update hermes agent + clean
maid -e hermes -f      # doctor --fix
maid -c hermes-img     # rm old hermes-dev image
maid -u hermes-img     # rebuild hermes-dev with --pull --no-prune
```

## Testing

Every domain is split into a **pure spec builder** (no side effects) and a thin
**effect layer** (execution), so it is unit-testable without invoking docker.

```nu
nu tests/run.nu        # runs all domains, prints TAP-style summary
```

| Suite | Covers |
|-------|--------|
| `result_test.nu` | Result monad: `ok`/`err`/`map`/`bind`/`unwrap-or` |
| `cmd_test.nu` | arg builders: `flag`/`opt`/`args`/`build` |
| `container_test.nu` | `get-container-engine` resolution |
| `hermes_spec_test.nu` | `dev-spec`/`panic-spec`/`build-spec` arg vectors |
| `maid_test.nu` | `get-targets` intersection, `maid-action` Result outcomes |
