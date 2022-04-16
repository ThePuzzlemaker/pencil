defmodule Pencil.Core.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: :pencil},
      {Pencil.Core.Wrapper.Watchdog, {}}
    ]

    opts = [strategy: :one_for_one, name: Pencil.Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
