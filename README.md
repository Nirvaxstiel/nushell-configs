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
}
```

Then `maid -r` to register it.

## Nushell integrations

`env.nu` only sets environment variables. Regenerate zoxide, Oh My Posh, and Carapace autoload files with:

```nu
nu-refresh-integrations
```

Restart Nushell after refresh. Generated files live in Nushell's vendor autoload directory and are not part of this repository. Vendor autoload files load in interactive startup; `nu -c` intentionally skips them.

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
