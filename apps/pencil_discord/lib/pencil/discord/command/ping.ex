defmodule Pencil.Discord.Command.Ping do
  use Pencil.Discord.Command

  @impl true
  def names(), do: ["ping", "pong"]

  @impl true
  def description(),
    do: {
      """
      Ping the bot to test it. This command is helpful for making sure the bot is not broken.
      """,
      nil
    }

  @impl true
  def execute([], message) do
    sent =
      Api.create_message!(message, %{
        embed: %{
          Util.begin_embed()
          | title: "Ping... \u{1f3d3}",
            description: "One second, I'm gathering data."
        }
      })

    ts = sent.timestamp

    Api.edit_message!(sent, %{
      embed: %{
        Util.begin_embed()
        | title: "Ping... Pong! \u{1f3d3}",
          fields: [
            %Embed.Field{
              name: "Command Recieve->Response Latency",
              value: "#{DateTime.diff(ts, message.timestamp, :millisecond)}ms"
            }
          ]
      }
    })

    :ok
  end
end
