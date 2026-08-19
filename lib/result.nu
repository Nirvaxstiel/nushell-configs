def ok [val?: any] {
  { ok: true, val: $val, err: null }
}

def err [e?: any] {
  { ok: false, val: null, err: $e }
}

def result-is-ok [r: record] {
  $r.ok == true
}

def result-is-err [r: record] {
  $r.ok == false
}

def map [r: record, fn: closure] {
  if ($r.ok == true) { ok (do $fn $r.val) } else { $r }
}

def bind [r: record, fn: closure] {
  if ($r.ok == true) { do $fn $r.val } else { $r }
}

def unwrap-or [r: record, default: any] {
  if ($r.ok == true) { $r.val } else { $default }
}
