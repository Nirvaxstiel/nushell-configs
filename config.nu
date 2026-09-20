$env.config.show_banner = false
$env.config.shell_integration."osc133" = false
source ($nu.default-config-dir | path join ".common.nu")
source ($nu.default-config-dir | path join ".integrations.nu")
source ($nu.default-config-dir | path join ".maid" "init.nu")
source ($nu.default-config-dir | path join ".fzf.nu")
source ($nu.default-config-dir | path join ".hermes-agent.nu")
source ($nu.default-config-dir | path join ".deepseek-harness.nu")
source ($nu.default-config-dir | path join ".path.nu")