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
}
```

Then `maid -r` to register it.

> [!NOTE]
> Personal config — strip zoxide, oh-my-posh, and anything else before using if you don't have them

## Files

| File | Purpose |
|---|---|
| `catalog.nu` | known tools + commands |
| `registry.json` | tools this machine has |
| `init.nu` | command definitions |
| `custom.nu` | your additions (not sourced) |
