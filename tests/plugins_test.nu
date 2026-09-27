source ../.plugins.nu
source ../tests/harness.nu

let nu_dir = ($nu.current-exe | path dirname | path expand)
let bogus_dir = ($nu_dir | path join "no-such-nu-install")

let plugins_test = [
    { name: "plugin-exe-path names the bundled binary", run: {
        assert-equal (plugin-exe-path $nu_dir "inc" | path basename) "nu_plugin_inc.exe"
    } }
    { name: "usable-plugin accepts a loaded binary next to nu", run: {
        let entry = { name: inc status: "loaded" filename: (plugin-exe-path $nu_dir "inc") }
        assert-true (usable-plugin $nu_dir "inc" $entry)
    } }
    { name: "usable-plugin rejects unloaded, wrong-path, and absent binaries", run: {
        let unloaded = { name: inc status: "registered" filename: (plugin-exe-path $nu_dir "inc") }
        assert-true (not (usable-plugin $nu_dir "inc" $unloaded))
        let stale = { name: inc status: "loaded" filename: (plugin-exe-path $bogus_dir "inc") }
        assert-true (not (usable-plugin $nu_dir "inc" $stale))
        let deleted = { name: inc status: "loaded" filename: (plugin-exe-path $bogus_dir "inc") }
        assert-true (not (usable-plugin $bogus_dir "inc" $deleted))
    } }
    { name: "unloaded-plugins reports every core plugin on an empty registry", run: {
        assert-equal (unloaded-plugins $nu_dir []) [gstat inc polars formats query]
    } }
    { name: "unloaded-plugins reports nothing when all core plugins load", run: {
        let entries = (unloaded-plugins $nu_dir [] | each { |plugin|
            { name: $plugin status: "loaded" filename: (plugin-exe-path $nu_dir $plugin) }
        })
        assert-equal (unloaded-plugins $nu_dir $entries) []
    } }
    { name: "absent-binaries names a directory without plugin binaries", run: {
        assert-equal (absent-binaries $bogus_dir) [gstat inc polars formats query]
    } }
]
