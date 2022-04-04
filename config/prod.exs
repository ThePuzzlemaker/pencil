import Config

# Suppress debug messages.
config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]
