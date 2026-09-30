source ../.carapace.nu
source ../tests/harness.nu

let fixture_dir = ($nu.default-config-dir | path join "tests" "fixtures")

def fixture-spec [] {
    do { cd $fixture_dir; argparse-spec python "fixture_cli:factory=toolx" }
}

let carapace_spec_test = [
    { name: "walker reads aliases, switches and value flags", run: {
        let spec = (fixture-spec)
        assert-equal $spec.name toolx
        assert-equal $spec.flags.'-v'.description "Verbose output"
        assert-equal ($spec.flags.'--verbose' | columns) [description]
        assert-equal $spec.flags.'--mode'.nargs 1
    } }
    { name: "walker turns argparse choices into flag completions", run: {
        assert-equal (fixture-spec).completion.flag.'--mode' [fast slow auto]
    } }
    { name: "walker recurses through subparsers with their descriptions", run: {
        let run = ((fixture-spec).commands | where name == run | first)
        assert-equal $run.description "Run the thing"
        assert-equal ($run.commands | get name) [now]
        assert-equal ($run.flags | columns | sort) [--help --jobs -h -j]
    } }
    { name: "carapace-spec-path keeps the name carapace registers", run: {
        assert-equal (carapace-spec-path hermes | path basename) "hermes.yaml"
    } }
    { name: "carapace-specs-dir targets the carapace specs directory", run: {
        assert-equal (carapace-specs-dir | path dirname | path basename) "carapace"
        assert-equal (carapace-specs-dir | path basename) "specs"
    } }
]
