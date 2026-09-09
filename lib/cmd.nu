def flag [parts: list<string>, cond: bool, name: string] {
  if $cond { $parts | append $name } else { $parts }
}

def opt [parts: list<string>, value: any, name: string] {
  if ($value | is-not-empty) { $parts | append $name | append $value } else { $parts }
}

def build [...segments: list<string>] {
  $segments | flatten
}
