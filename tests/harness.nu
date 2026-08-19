# Minimal test harness. No external deps.
# A test is a closure that returns an Ok/Nil on pass or errors on fail.
# Assertions:
#   assert-equal [got, want]
#   assert-true  [cond]
#   assert-is-err [r] / assert-is-ok [r]

def assert-equal [got: any, want: any] {
    if ($got | to nuon) != ($want | to nuon) {
        error make { msg: $"assert-equal FAILED\n  got:  ($got | to nuon)\n  want: ($want | to nuon)" }
    }
}

def assert-true [cond: bool] {
    if not $cond { error make { msg: "assert-true FAILED: expected true" } }
}

def assert-is-ok [r: record] {
    if not ($r.ok == true) { error make { msg: $"assert-is-ok FAILED: ($r | to nuon)" } }
}

def assert-is-err [r: record] {
    if not ($r.ok == false) { error make { msg: $"assert-is-err FAILED: ($r | to nuon)" } }
}
