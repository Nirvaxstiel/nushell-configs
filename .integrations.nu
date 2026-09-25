def patch-omp-nu [] {
    let script = ($in | str replace "$env.CMD_DURATION_MS != '0823'" "$env.CMD_DURATION_MS != 823")
    if ($script | str contains "$env.CMD_DURATION_MS != 823") {
        $script | str replace '$execution_time = $env.CMD_DURATION_MS' '$execution_time = ($env.CMD_DURATION_MS | into int)'
    } else {
        $script
    }
}

def patch-carapace-scoop-path []: string -> string {
    let path = (which carapace | get 0?.path?)
    if $path == null or $path !~ '(?i)[\\/]scoop[\\/]shims[\\/]' {
        return $in
    }
    $in
    | str replace --multiline --regex '^\$env\.Path = .*/carapace/bin"\)\r?\n\r?\n' ''
    | str replace 'carapace $spans.0 nushell ...$spans
  | from json' 'carapace $spans.0 nushell ...$spans
  | from json
  | if ($in | is-empty) { null } else { $in }'
}

def nu-refresh-integrations [] {
    let vendor_autoload_dir = ($nu.data-dir | path join "vendor" "autoload")
    mkdir $vendor_autoload_dir | ignore
    zoxide init nushell
        | save --force ($vendor_autoload_dir | path join "zoxide.nu")
    oh-my-posh init nu --config ~/.config/omp/ys.xtended.json --print
        | patch-omp-nu
        | save --force ($vendor_autoload_dir | path join "oh-my-posh.nu")
    carapace _carapace nushell
        | patch-carapace-scoop-path 
        | save --force ($vendor_autoload_dir | path join "carapace.nu")
    print "integrations refreshed; restart Nushell to load them"
}
