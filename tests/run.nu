source ../.common.nu
source ../lib/result.nu
source ../lib/cmd.nu
source ../hermes/container.nu
source ../hermes/spec.nu
source ../.maid/core.nu
source ./harness.nu
source ./result_test.nu
source ./cmd_test.nu
source ./container_test.nu
source ./hermes_spec_test.nu
source ./maid_test.nu

# Flatten every domain's case list and run them, reporting a TAP-ish summary.
let all = ($result_test ++ $cmd_test ++ $container_test ++ $hermes_spec_test ++ $maid_test)

let results = ($all | each { |case|
    try { do $case.run; { name: $case.name, ok: true } } catch { |e|
        { name: $case.name, ok: false, msg: $e.msg }
    }
})

let passed_results = ($results | where ok == true)
let failed_results = ($results | where ok == false)

$passed_results | each { |r| print $"ok   - ($r.name)" }
$failed_results | each { |r|
    print $"FAIL - ($r.name)"
    print $"      ($r.msg | str replace --all '\n' '\n      ')"
}

let passed = ($passed_results | length)
let failed = ($failed_results | length)
let failures = ($failed_results | get name)

print ""
print $"($passed) passed, ($failed) failed, (($passed + $failed)) total"

if $failed > 0 {
    print "FAILURES:"; $failures | each { |n| print $"  - ($n)" }
    exit 1
}
