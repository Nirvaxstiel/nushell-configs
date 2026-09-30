def patch-omp-nu [] {
    let script = ($in | str replace "$env.CMD_DURATION_MS != '0823'" "$env.CMD_DURATION_MS != 823")
    if ($script | str contains "$env.CMD_DURATION_MS != 823") {
        $script | str replace '$execution_time = $env.CMD_DURATION_MS' '$execution_time = ($env.CMD_DURATION_MS | into int)'
    } else {
        $script
    }
}

def carapace-exe [] {
    let resolved = (which carapace | get 0?.path?)
    if $resolved == null { return null }
    let shim = ($resolved | str replace --regex '(?i)\.exe$' '.shim')
    if not ($shim | path exists) { return $resolved }
    let target = (open $shim | lines | parse 'path = "{path}"' | get 0?.path?)
    if $target == null or not ($target | path exists) { return $resolved }
    $target
}

def nu-refresh-integrations [] {
    let vendor_autoload_dir = ($nu.data-dir | path join "vendor" "autoload")
    mkdir $vendor_autoload_dir | ignore
    zoxide init nushell
        | save --force ($vendor_autoload_dir | path join "zoxide.nu")
    oh-my-posh init nu --config ~/.config/omp/ys.xtended.json --print
        | patch-omp-nu
        | save --force ($vendor_autoload_dir | path join "oh-my-posh.nu")
    print "integrations refreshed; restart Nushell to load them"
}

let carapace_exe = (carapace-exe)

let carapace_completer = {|place|
    if $carapace_exe == null or ($place.command | length) == 0 { return null }
    let words = ($place.command | skip 1 | prepend ($place.command.0 | str replace --regex '\.exe$' ''))
    with-env {
        CARAPACE_SHELL: 'nushell'
        CARAPACE_SHELL_ALIASES: (scope aliases | get name | uniq | str join "\n")
        CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq | str join "\n")
        CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq | str join "\n")
        CARAPACE_SHELL_VARIABLES: (scope variables | get name | uniq | str join "\n")
    } {
        ^$carapace_exe $words.0 nushell ...$words | from json
    }
}

$env.config = ($env.config | upsert completions.external {
    enable: true
    max_results: 1000
    completer: $carapace_completer
})
