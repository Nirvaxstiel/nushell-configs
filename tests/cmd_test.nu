source ../lib/cmd.nu
source ../tests/harness.nu

let cmd_test = [
    { name: "flag appends when true", run: { assert-equal (flag [a] true b) [a b] } }
    { name: "flag omits when false", run: { assert-equal (flag [a] false b) [a] } }
    { name: "opt appends when non-empty", run: { assert-equal (opt [a] 5 "--n") [a --n 5] } }
    { name: "opt omits when null", run: { assert-equal (opt [a] null "--n") [a] } }
    { name: "build flattens nested segments", run: {
        assert-equal (build [a] [b c] [] [d]) [a b c d]
    } }
]
