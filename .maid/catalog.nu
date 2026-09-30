# hermes runs two ways: a local CLI, or in a container. The Dockerfile in this
# config is one container approach, not the definition of the tool.
def hermes-cli [] {
    (which hermes | is-not-empty)
}

def hermes-container [] {
    (which docker | is-not-empty) and ((($nu.default-config-dir | path join "hermes" "Dockerfile") | path exists))
}

def hermes-python [] {
    let python = ($nu.home-dir | path join ".hermes" "hermes-agent" ".venv" "Scripts" "python.exe")
    if not ($python | path exists) { error make { msg: $"hermes venv python not found at ($python)" } }
    $python
}

def hermes-pathway [cli: bool, container: bool] {
    if $cli and $container { "hermes/local+container" } else if $cli { "hermes/local" } else if $container { "hermes/container" } else { null }
}

let MAID_CATALOG = [
  {
    name: bun
    category: package-manager
    detect: {|| which bun }
    clean: {|| bun cache clean --force }
    prune: null
    update: {|| bun upgrade }
    audit: {|| bun audit }
    audit_fix: {|| bun audit --fix }
    spec: null
  }
  {
    name: npm
    category: package-manager
    detect: {|| which npm }
    clean: {|| npm cache clean --force }
    prune: null
    update: {|| npm update -g }
    audit: {|| npm audit }
    audit_fix: {|| npm audit fix }
    spec: null
  }
  {
    name: pnpm
    category: package-manager
    detect: {|| which pnpm }
    clean: null
    prune: {|| pnpm store prune }
    update: {|| pnpm up -g }
    audit: {|| pnpm audit }
    audit_fix: {|| pnpm audit fix }
    spec: null
  }
  {
    name: uv
    category: package-manager
    detect: {|| which uv }
    clean: {|| uv cache clean }
    prune: null
    update: {|| uv self update }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: scoop
    category: package-manager
    detect: {|| which scoop }
    clean: {||
      scoop cache rm -a
      scoop cleanup -a
    }
    prune: null
    update: {||
      scoop update
      scoop update -a
    }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: choco
    category: package-manager
    detect: {|| which choco }
    clean: {|| ^choco cache clear --force }
    prune: null
    update: {|| ^choco upgrade all -y }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: cargo
    category: toolchain
    detect: {|| which cargo }
    clean: {|| cargo cache --autoclean }
    prune: null
    update: {|| cargo install-update -a }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: dotnet
    category: sdk
    detect: {|| which dotnet }
    clean: {|| ^dotnet nuget locals all --clear }
    prune: null
    update: {|| ^dotnet tool update --all --global }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: rustup
    category: toolchain
    detect: {|| which rustup }
    clean: null
    prune: {|| rustup toolchain prune }
    update: {|| rustup update }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: gem
    category: package-manager
    detect: {|| which gem }
    clean: {|| gem cleanup }
    prune: null
    update: {|| gem update --system }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: pip
    category: package-manager
    detect: {|| which pip }
    clean: {|| pip cache purge }
    prune: null
    update: {|| python -m pip install --upgrade pip }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: docker
    category: container
    detect: {|| which docker }
    clean: {||
      ^docker builder prune -f --filter type!=exec.cachemount
      ^docker image prune -f
      ^docker image prune -f --filter "dangling=true"
    }
    prune: {||
      ^docker container prune -f
      ^docker network prune -f
      ^docker volume prune -f
    }
    update: {|| ^docker pull nousresearch/hermes-agent:latest }
    audit: null
    audit_fix: null
    spec: null
  }
  {
    name: hermes
    category: agent
    detect: {|| hermes-pathway (hermes-cli) (hermes-container) }
    clean: {||
      if (hermes-cli) {
        hermes sessions prune
        hermes checkpoints prune --retention-days 7
      }
      if (hermes-container) {
        ^docker image rm hermes-dev 2>/dev/null; null
      }
    }
    prune: {||
      if (hermes-cli) { hermes checkpoints prune }
    }
    update: {||
      if (hermes-cli) { hermes update }
      if (hermes-container) { hermes-build --pull --no-prune }
    }
    audit: {||
      if (hermes-cli) { hermes doctor }
    }
    audit_fix: {||
      if (hermes-cli) { hermes doctor --fix }
    }
    spec: {|| carapace-spec-write (argparse-spec (hermes-python) "hermes_cli.main:_build_cli_parser=hermes") }
  }
]