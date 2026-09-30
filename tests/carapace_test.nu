source ../.integrations.nu
source ../tests/harness.nu

alias gco = git checkout

let carapace_test = [
    { name: "carapace-exe resolves a real binary, not the scoop shim", run: {
        let exe = (carapace-exe)
        assert-true ($exe != null)
        assert-true ($exe | path exists)
        assert-true (not ($exe =~ '(?i)[\\/]shims[\\/]'))
    } }
    { name: "external completer is enabled with a raised result cap", run: {
        assert-true $env.config.completions.external.enable
        assert-true ($env.config.completions.external.max_results > 100)
    } }
    { name: "engine routes external commands to carapace", run: {
        assert-true (("docker run --" | commandline complete | length) > 100)
    } }
    { name: "engine returns more than the old 100-result cap for git", run: {
        assert-true (("git " | commandline complete | length) > 100)
    } }
    { name: "alias heads reach carapace with their arguments intact", run: {
        let rows = ("gco " | commandline complete)
        assert-true (($rows | length) > 0)
        assert-true (($rows | any { |v| $v == "checkout" }) == false)
    } }
    { name: "unknown commands fall back instead of erroring", run: {
        assert-true (("nosuchcmd12345 --" | commandline complete | length) == 0)
    } }
]
