import Config

config :pencil_core, :minecraft,
  version: "1.18.2",
  jar: "server.jar",
  wrapper_bin: "./target/release/server-command-wrapper",
  jvm_args: ["-Xms4G", "-Xmx6G"],
  server_args: ["-nogui"]

# Updater is currently nonexistent.
config :pencil_core, :updater,
  enabled: true,
  version_file: "version.txt",
  check_every: ~T[12:00:00],
  check_on_restart: true

config :nostrum,
  token: "DISCORD_BOT_TOKEN"

config :pencil_discord, :bot,
  # Notification channel ID (note: in the future this may allow multiple channels)
  notify_channel: 12_345_678,
  # Minecraft server admin role ID
  role_id: 12_345_678,
  # Bot owner user IDs
  superusers: [12_345_678]
