defmodule Pencil.Discord.Notifier do
  use GenServer

  alias Phoenix.PubSub
  alias Nostrum.Api
  alias Pencil.Discord.Util
  alias Nostrum.Struct.Embed

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    notify_channel = Keyword.get(opts, :notify_channel)
    role_id = Keyword.get(opts, :role_id)
    PubSub.subscribe(:pencil, "server_status")
    {:ok, %{notify_channel: notify_channel, role_id: role_id}}
  end

  @impl true
  def handle_info(:crash, %{notify_channel: notify_channel, role_id: role_id} = state) do
    Api.create_message!(
      notify_channel,
      %{
        content: "(attn <@&#{role_id}>)",
        embed: %{
          Util.begin_embed(:error)
          | title: "Status Notification",
            fields: [
              %Embed.Field{
                name: "What happened",
                value: "The server crashed."
              },
              %Embed.Field{
                name: "What to do",
                value:
                  "I'm restarting the server right now. You don't need to do anything at the moment."
              }
            ]
        },
        allowed_mentions: [{:roles, [role_id]}]
      }
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(:permacrash, %{notify_channel: notify_channel, role_id: role_id} = state) do
    Api.create_message!(
      notify_channel,
      %{
        content: "(attn <@&#{role_id}>)",
        embed: %{
          Util.begin_embed(:error)
          | title: "Status Notification",
            fields: [
              %Embed.Field{
                name: "What happened",
                value: "The server has entered a restart loop."
              },
              %Embed.Field{
                name: "What to do",
                value: "Please diagnose the issue, then manually restart the server."
              }
            ]
        },
        allowed_mentions: [{:roles, [role_id]}]
      }
    )

    {:noreply, state}
  end

  @impl true
  def handle_info(:started, %{notify_channel: notify_channel} = state) do
    Api.create_message!(
      notify_channel,
      %{
        embed: %{
          Util.begin_embed()
          | title: "Status Notification",
            fields: [
              %Embed.Field{
                name: "What happened",
                value: "The server has started."
              }
            ]
        }
      }
    )

    {:noreply, state}
  end
end
