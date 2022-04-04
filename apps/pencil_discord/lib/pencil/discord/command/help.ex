defmodule Pencil.Discord.Command.Help do
  use Pencil.Discord.Command

  @usage_key """
  `<argument name>`: this argument is required
  `[argument name]`: this argument is optional
  """

  @impl true
  def names(), do: ["help"]

  @impl true
  def description(),
    do: {
      """
      Show help for how to use commands. When you don't provide a command, this will list the commands you can run.
      """,
      nil
    }

  @impl true
  def usage(),
    do: """
    help [command]
    """

  defp nonexist(message, cmd_name) do
    Api.create_message(message, %{
      embed: %{
        Util.begin_embed(:error)
        | title: "Help",
          description: """
          The command `#{cmd_name}` does not exist.
          #{Command.did_you_mean(cmd_name)}
          """
      }
    })
  end

  @impl true
  def execute([cmd_name], message) do
    case Command.Registry.lookup(cmd_name) do
      nil ->
        {:ok, _} = nonexist(message, cmd_name)

      mod ->
        if mod.show_in_help() do
          names = mod.names() |> Enum.map(&"`#{&1}`")
          {oneliner, extra} = mod.description()
          usage = mod.usage()

          fields = [
            %Embed.Field{
              inline: true,
              name: "Name#{unless length(names) == 1, do: "s", else: ""}",
              value: "#{Enum.join(names, ", ")}"
            }
          ]

          fields =
            if is_nil(oneliner) do
              fields ++
                [
                  %Embed.Field{
                    inline: true,
                    name: "Description",
                    value: "Sorry, no description for this command is available."
                  }
                ]
            else
              extra = if not is_nil(extra), do: "\n#{extra}", else: ""

              fields ++
                [
                  %Embed.Field{
                    inline: true,
                    name: "Description",
                    value: """
                    #{oneliner}
                    #{extra}
                    """
                  }
                ]
            end

          fields =
            if not is_nil(usage) do
              fields ++
                [
                  %Embed.Field{
                    inline: true,
                    name: "Usage",
                    value: """
                    `#{usage}`
                    """
                  },
                  %Embed.Field{
                    inline: false,
                    name: "Usage Key",
                    value: @usage_key
                  }
                ]
            else
              fields
            end

          Api.create_message!(message, %{
            embed: %{
              Util.begin_embed()
              | title: "Help",
                fields: fields
            }
          })
        else
          {:ok, _} = nonexist(message, cmd_name)
        end
    end

    :ok
  end

  @impl true
  def execute([], message) do
    handlers =
      Command.Registry.all_unique_commands()
      |> Enum.reject(&(not &1.show_in_help()))
      |> Enum.map(fn mod ->
        "`#{List.first(mod.names())}`"
      end)

    Api.create_message!(message, %{
      embed: %{
        Util.begin_embed()
        | title: "Help",
          fields: [
            %Embed.Field{
              inline: false,
              name: "Commands",
              value: "#{Enum.join(handlers, "\n")}"
            }
          ]
      }
    })

    :ok
  end

  defparsec(:parse_args, optional(word()))
end
