import Config

config :logger,
  backends: [:console]

config :logger, :console,
  format: "$date $time $metadata[$level]$levelpad $message\n",
  metadata: [:application]

config :nostrum,
  gateway_intents: [:guild_messages, :direct_messages],
  caches: %{presences: Nostrum.Cache.PresenceCache.NoOp}

# change to whatever prefix you wish
config :pencil_discord, :bot, prefix: "pencil "

import_config "#{config_env()}.exs"

# local build configuration--I use this to not clog up git with stuff specific to my configuration.
if File.exists?(Path.expand("./#{config_env()}.local.exs", __DIR__)) do
  import_config "#{config_env()}.local.exs"
end
