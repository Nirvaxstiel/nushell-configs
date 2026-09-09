def preferred-paths [] {
  let os = ($nu.os-info.name | str lowercase)
  let home = if $os == "windows" { $env.USERPROFILE } else { $env.HOME }

  let local_bin = if $os == "windows" {
    $'($home)\.local\bin'
  } else {
    $'($home)/.local/bin'
  }

  let podman_bin = if $os == "windows" {
    'C:\Program Files\Podman\bin'
  } else {
    '/opt/podman/bin'
  }

  [$local_bin $podman_bin]
}

def dedupe [xs: list<string>] {
  $xs | reduce --fold [] {|item, acc|
    if $item in $acc { $acc } else { $acc | append $item }
  }
}

def ensure-front [existing: list<string>, desired: list<string>] {
  let existing = (dedupe $existing)
  let desired = ($desired | where {|item| $item not-in $existing })
  ($desired | append $existing)
}

$env.PATH = (ensure-front $env.PATH (preferred-paths))
