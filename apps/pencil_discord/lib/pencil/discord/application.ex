defmodule Pencil.Discord.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Pencil.Discord.Command.Registry, []},
      # == Why do we only start one consumer? ==
      # This bot is only really meant to be one one or *maybe* two servers at
      # once. If you find a legitimate use-case in which you need more (and
      # thus need the extra performance of multiple consumers), please let me
      # know!
      {Pencil.Discord.Consumer, []},
      {Pencil.Discord.Notifier, Application.fetch_env!(:pencil_discord, :bot)}
    ]

    opts = [strategy: :rest_for_one, name: Pencil.Discord.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
