import Config

config :nostrum,
  token: "DISCORD_BOT_TOKEN"

config :pencil_discord, :bot,
  # Notification channel ID (note: in the future this may allow multiple channels)
  notify_channel: 12_345_678,
  # Minecraft server admin role ID
  role_id: 12_345_678,
  # Bot owner user IDs
  superusers: [12_345_678]
