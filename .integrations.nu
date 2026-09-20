def patch-omp-nu [] {
    let script = ($in | str replace "$env.CMD_DURATION_MS != '0823'" "$env.CMD_DURATION_MS != 823")
    if ($script | str contains "$env.CMD_DURATION_MS != 823") {
        $script | str replace '$execution_time = $env.CMD_DURATION_MS' '$execution_time = ($env.CMD_DURATION_MS | into int)'
    } else {
        $script
    }
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
        | save --force ($vendor_autoload_dir | path join "carapace.nu")
    print "integrations refreshed; restart Nushell to load them"
}
