defmodule Pencil.Discord.Command.Invalid do
  use Pencil.Discord.Command

  @impl true
  def names(), do: []

  @impl true
  def execute([], message) do
    {:ok, parsed, _, _, _, _} = Command.Parser.command(message.content)
    cmd_name = Keyword.get(parsed, :cmd_name)

    Api.create_message!(message, %{
      embed: %{
        Util.begin_embed(:error)
        | title: "Error",
          description: """
          The command `#{cmd_name}` does not exist.
          #{Command.did_you_mean(cmd_name)}
          """
      }
    })

    :ok
  end
end
