mkdir ($nu.data-dir | path join "vendor/autoload")
zoxide init nushell
    | save -f ($nu.data-dir | path join vendor/autoload/zoxide.nu)

oh-my-posh init nu --config ~/.config/omp/ys.xtended.json --print
    | patch-omp-nu
    | save -f ($nu.data-dir | path join vendor/autoload/oh-my-posh.nu)

# starship init nu 
#     | save -f ($nu.data-dir | path join vendor/autoload/starship.nu)

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

def patch-omp-nu [] {
    $in
    | str replace "$env.CMD_DURATION_MS != '0823'" "$env.CMD_DURATION_MS != 823"
    | if ($in | str contains "$env.CMD_DURATION_MS != 823") {
        str replace '$execution_time = $env.CMD_DURATION_MS' '$execution_time = ($env.CMD_DURATION_MS | into int)'
    } else {
        $in
    }
}