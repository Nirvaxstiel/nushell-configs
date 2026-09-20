def ok [value: any] {
  { kind: "ok", value: $value }
}

def err [error: any] {
  { kind: "err", error: $error }
}

def result-is-ok [result: record] {
  ($result.kind? | default "") == "ok"
}

def result-is-err [result: record] {
  ($result.kind? | default "") == "err"
}

def map [result: record, fn: closure] {
  if (result-is-ok $result) { ok (do $fn $result.value) } else { $result }
}

def bind [result: record, fn: closure] {
  if (result-is-ok $result) { do $fn $result.value } else { $result }
}

def unwrap-or [result: record, default: any] {
  if (result-is-ok $result) { $result.value } else { $default }
}
