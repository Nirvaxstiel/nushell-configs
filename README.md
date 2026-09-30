# maid

Personal dev environment cleanup tool using nushell functions

## Usage

```
maid -l              list registered tools
maid -c <name>       clean a tool
maid -c -a           clean all
maid -p <name>       prune a tool
maid -p -a           prune all
maid -u <name>       update + clean a tool
maid -u -a           update + clean all
maid -e <name>       audit a tool (security/vulns)
maid -e <name> -f    audit + auto-fix vulnerabilities
maid -e -a           audit all
maid -a              clean + prune all
maid -s <name>       refresh the tool's carapace spec
maid -s -a           refresh all carapace specs
maid -r              probe for installed tools
```

## Add a tool

Edit `.maid/catalog.nu`:

```nu
{
  name:     "mytool"
  category: "package-manager"
  detect:   "^where mytool"
  clean:    {|| mytool cache clean }
  prune:    null
  update:   null
  audit:    null
  audit_fix: null
  spec:     null
}
```

Then `maid -r` to register it.

Every entry declares the same nine fields, so `maid-action` can look any action up by name; a test enforces that uniformity. `spec` is the tool's carapace completion definition and is driven by the catalog rather than the registry, because a tool can declare a spec on a machine where its `detect` closure reports nothing. For a CLI whose surface is argparse-based, `spec: {|| carapace-spec-write (argparse-spec mytool)}` derives it from `--help`, and `maid -s mytool` refreshes it.

`hermes` installs two ways — a local CLI or a container — and the Dockerfile in this repo is one container approach, not the definition of the tool. Its actions branch on `hermes-cli` and `hermes-container` instead of assuming the container path: updates come from `hermes update` on the bare-metal pathway and from `hermes-build` for the container backend, and the CLI-only actions (`sessions`/`checkpoints prune`, `doctor`) run only when the CLI is present.

## Nushell integrations

`env.nu` only sets environment variables. Regenerate the zoxide and Oh My Posh autoload files with:

```nu
nu-refresh-integrations
```

Restart Nushell after refresh. Generated files live in Nushell's vendor autoload directory and are not part of this repository. Vendor autoload files load in interactive startup; `nu -c` intentionally skips them.

## Carapace completions

The completer lives in `.integrations.nu` instead of coming from `carapace _carapace nushell`. Carapace's generated template changes between versions and patching it rots silently; owning it also lets `carapace-exe` call the real binary behind the scoop shim, saving ~90 ms per Tab press. `completions.external.max_results` is raised from the default 100, which truncates real result sets (`git <TAB>` returns 167 entries).

`env.nu` sets `CARAPACE_BRIDGES = "bash"` (fish, zsh, and inshellisense are not installed, so those bridges were inert), `CARAPACE_LENIENT`, and `CARAPACE_MATCH`.

## Carapace specs

Carapace has no spec for `hermes`, and no bridge can supply one: `carapace --detect hermes` finds nothing, and `hermes completion bash` is a hand-written script rather than argcomplete/click machinery. The `spec` action on the `hermes` catalog entry builds it — `maid -s hermes`, or `maid -s -a` for every tool that declares one — by parsing `hermes --help` for the root command and each subcommand in parallel: about 100 s for 69 commands and 284 subcommands, writing `hermes.yaml` (69 KB) into carapace's specs directory. It needs the local CLI on `PATH`, because that is what it interrogates.

Two format rules come from carapace's loader, not from the docs: the file must live in `<UserConfigDir>/carapace/specs`, and `Specs()` only registers names matching `^[a-zA-Z0-9_\-.]+\.yaml$`, so the filename must match the spec `name` and use the `.yaml` extension — a `.json` spec is silently ignored. Run the refresh after a hermes upgrade; the spec covers flags and descriptions to two subcommand levels.

## Nushell core plugins

The release zip ships `nu_plugin_*.exe` next to `nu.exe` and registers none of them, and `plugin add` is a manual step. `config.nu` loads `.plugins.nu` and calls `nu-bootstrap-core-plugins`, which registers the allowlisted core plugins (`gstat`, `inc`, `polars`, `formats`, `query`) from the nu directory on the first launch after an install or upgrade, then prints a restart notice.

The per-launch check is a `plugin list` comparison against the allowlist by resolved path, not by status: a plugin counts as usable only when its status is `loaded`/`running`, its recorded path resolves to the binary next to the current `nu.exe`, and that binary still exists on disk. A missing binary is reported by name instead of failing silently. `plugin.msgpackz` is generated machine state and is not tracked.

## DeepSeek harness

`dsh` builds from a pinned commit. Set `DSH_COMMIT` to another full 40-character SHA when needed, or pass `dsh --latest` to explicitly resolve `master`.

## Files

| File | Purpose |
|---|---|
| `catalog.nu` | known tools + commands |
| `registry.json` | tools this machine has |
| `init.nu` | command definitions |
| `custom.nu` | your additions (not sourced) |
