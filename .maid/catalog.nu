let MAID_CATALOG = [
  {
    name: bun
    category: package-manager
    detect: "^where bun"
    clean: {|| bun cache clean --force }
    prune: null
    update: null
  }
  {
    name: npm
    category: package-manager
    detect: "^where npm"
    clean: {|| npm cache clean --force }
    prune: null
    update: null
  }
  {
    name: pnpm
    category: package-manager
    detect: "^where pnpm"
    clean: null
    prune: {|| pnpm store prune }
    update: null
  }
  {
    name: uv
    category: package-manager
    detect: "^where uv"
    clean: {|| uv cache clean }
    prune: null
    update: null
  }
  {
    name: scoop
    category: package-manager
    detect: "^where scoop"
    clean: {||
      scoop cache rm -a
      scoop cleanup -a
    }
    prune: null
    update: {||
      scoop update
      scoop update -a
    }
  }
  {
    name: choco
    category: package-manager
    detect: "^where choco"
    clean: {|| ^choco cache clear --force }
    prune: null
    update: {|| ^choco upgrade all -y }
  }
  {
    name: cargo
    category: toolchain
    detect: "^where cargo"
    clean: {||
      let result = (^cargo clean gc --max-download-age=30days | complete)
      if ($result.exit_code != 0) {
        print "cargo: native GC not available, using manual cleanup"
        let cargo_home = ($env.USERPROFILE | path join ".cargo")
        let max_age = (date now) - 30day
        let cache_dir = ($cargo_home | path join "registry" "cache")
        if ($cache_dir | path exists) {
          ls ($cache_dir | path join "**" "*")
          | where type == file and modified < $max_age
          | each {|file|
            print $"Removing: ($file.name)"
            rm --force $file.name
          }
        }
      }
    }
    prune: null
    update: null
  }
  {
    name: dotnet
    category: sdk
    detect: "^where dotnet"
    clean: {|| ^dotnet nuget locals all --clear }
    prune: null
    update: {|| ^dotnet tool update --all --global }
  }
  {
    name: rustup
    category: toolchain
    detect: "^where rustup"
    clean: null
    prune: {|| rustup toolchain prune }
    update: {|| rustup update }
  }
  {
    name: gem
    category: package-manager
    detect: "^where gem"
    clean: {|| gem cleanup }
    prune: null
    update: {|| gem update --system }
  }
  {
    name: pip
    category: package-manager
    detect: "^where pip"
    clean: {|| pip cache purge }
    prune: null
    update: {|| python -m pip install --upgrade pip }
  }
]
