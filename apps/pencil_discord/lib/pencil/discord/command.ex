defmodule Pencil.Discord.Command do
  require Logger
  alias Pencil.Discord.Command.{Predicate, Parser}
  alias Pencil.Discord.Command.Registry, as: CommandRegistry
  alias Nostrum.Api
  alias Pencil.Discord.Util
  alias Nostrum.Struct.Message

  @prefix Application.compile_env!(:pencil_discord, [:bot, :prefix])

  @callback parse_args(binary) ::
              {:ok, [term], rest, context, line, byte_offset}
              | {:error, reason, rest, context, line, byte_offset}
            when line: {pos_integer, byte_offset},
                 byte_offset: pos_integer,
                 rest: binary,
                 reason: String.t(),
                 context: map
  @callback execute([term], Message.t()) ::
              :ok | {:error, term()} | Predicate.result()
  @callback names() :: [String.t()]
  @callback description() :: {oneliner :: String.t() | nil, extra :: String.t() | nil}
  @callback usage() :: String.t() | nil
  @callback predicates() :: [Predicate.t()]
  @callback show_in_help() :: boolean()
  @optional_callbacks parse_args: 1, predicates: 0

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Pencil.Discord.Command

      import NimbleParsec
      import Pencil.Discord.Command.Parser
      import Pencil.Discord.Command.Parser.Helpers
      alias Nostrum.Api
      alias Nostrum.Struct.Embed
      alias Pencil.Discord.Util
      alias Pencil.Discord.Command
      alias Pencil.Discord.Command.Predicate
      require Predicate
      require Logger

      def description(), do: {nil, nil}
      def usage(), do: nil
      def show_in_help(), do: true
      defoverridable description: 0, usage: 0, show_in_help: 0
    end
  end

  def dispatch(message) do
    {:ok, parsed, rest, _, _, _} = Parser.command(message.content)
    cmd_name = Keyword.get(parsed, :cmd_name)

    mod = CommandRegistry.lookup(cmd_name) || Pencil.Discord.Command.Invalid

    with :next <- dispatch_run_predicates(message, mod) do
      parsed_args = dispatch_parse_args(message, rest, mod, cmd_name)
      mod.execute(parsed_args, message)
    else
      x -> x
    end
  end

  defp dispatch_run_predicates(message, mod) do
    if function_exported?(mod, :predicates, 0) do
      Predicate.evaluate(message, mod.predicates())
    else
      :next
    end
  end

  defp dispatch_parse_args(message, rest, mod, cmd_name) do
    if function_exported?(mod, :parse_args, 1) do
      with {:ok, parsed_args, _, _, _, _} <- mod.parse_args(String.trim_leading(rest)) do
        parsed_args |> Enum.reject(&(&1 == ""))
      else
        _ ->
          Api.create_message!(message, %{
            embed: %{
              Util.begin_embed(:error)
              | title: "Error",
                description:
                  "Sorry, I couldn't understand what you meant. Try using `#{String.trim(@prefix)} help #{cmd_name}`?"
            }
          })

          raise "bad parse of cmd args"
      end
    else
      []
    end
  end

  def did_you_mean(cmd_name) do
    close =
      CommandRegistry.find_close(cmd_name)
      |> Stream.reject(fn {_, mod} -> not mod.show_in_help() end)
      |> Stream.map(fn {name, _} -> "`#{name}`" end)
      |> Enum.take(5)

    case length(close) do
      0 -> ""
      1 -> "Did you mean #{close}?"
      _ -> "Did you mean one of these commands: #{Enum.join(close, ", ")}?"
    end
  end
end
