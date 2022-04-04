defmodule Pencil.Discord.Command.CmdReload do
  use Pencil.Discord.Command

  @impl true
  def names(), do: ["cmdreload", "reloadcmd"]

  @impl true
  def description(),
    do: {
      "Reload a command handler module.",
      "**This command is only runnable by bot administrators.**"
    }

  @impl true
  def usage(), do: "cmdreload <module>"

  @impl true
  def predicates(), do: [&Predicate.is_superuser?/1]

  @impl true
  def execute([name], message) do
    :ok = Pencil.Discord.Command.Registry.reload_handler(name)
    {:ok} = Api.create_reaction(message.channel_id, message.id, "\u2705")
    Logger.info("Successfully reloaded command handler `#{name}`.")
    :ok
  rescue
    e ->
      Logger.warning(
        "Failed to reload command handler `#{name}`: #{Exception.format(:error, e, __STACKTRACE__)}"
      )

      {:ok} = Api.create_reaction(message.channel_id, message.id, "\u274c")
  end

  defparsec(:parse_args, word())
end
