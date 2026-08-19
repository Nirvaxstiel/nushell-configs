source ../lib/result.nu
source ../tests/harness.nu

let result_test = [
    { name: "ok wraps value", run: { assert-equal (ok 42).val 42; assert-true (ok 42).ok } }
    { name: "err carries error", run: { assert-equal (err "x").err "x"; assert-true ((err "x").ok == false) } }
    { name: "is-ok / is-err classify", run: {
        assert-true (result-is-ok (ok 1))
        assert-true (result-is-err (err 1))
    } }
    { name: "map lifts on ok, skips on err", run: {
        let inc = { |x| $x + 1 }
        let m = (map (ok 1) $inc)
        assert-equal $m.val 2
        let e = (map (err "boom") $inc)
        assert-equal $e.err "boom"
    } }
    { name: "bind chains ok, short-circuits err", run: {
        let inc = { |x| ok ($x + 1) }
        let c = (bind (bind (ok 1) $inc) $inc)
        assert-equal $c.val 3
        let e = (bind (err "x") $inc)
        assert-equal $e.err "x"
    } }
    { name: "unwrap-or yields default on err, val on ok", run: {
        assert-equal (unwrap-or (err "x") 99) 99
        assert-equal (unwrap-or (ok 7) 99) 7
    } }
]
