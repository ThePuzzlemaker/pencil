import Config

config :logger,
  backends: [:console]

config :logger, :console,
  format: "$date $time $metadata[$level]$levelpad $message\n",
  metadata: [:application]

config :nostrum,
  gateway_intents: [:guild_messages, :direct_messages],
  caches: %{presences: Nostrum.Cache.PresenceCache.NoOp}

config :pencil_discord, :bot,
  # Change to whatever prefix you wish. This is space-sensitive,
  # i.e. prefix: "pencil " means "pencil ping" works,
  # prefix: "pencil" means "pencilping" works, but "pencil ping" doesn't.
  # This will likely change in the future.
  prefix: "pencil ",
  # The color, in hex, that embeds will have. Make sure this starts with `0x`
  # and doesn't include a `#`.
  embed_color: 0xFFD042

import_config "#{config_env()}.exs"

# local build configuration--I use this to not clog up git with stuff specific to my configuration.
if File.exists?(Path.expand("./#{config_env()}.local.exs", __DIR__)) do
  import_config "#{config_env()}.local.exs"
end
