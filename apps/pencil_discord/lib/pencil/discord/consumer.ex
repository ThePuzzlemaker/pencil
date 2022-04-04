defmodule Pencil.Discord.Consumer do
  use Nostrum.Consumer

  alias Pencil.Discord.{Command, Util}
  alias Pencil.Discord.Command.Registry, as: CommandRegistry
  alias Nostrum.Api

  require Logger

  def start_link() do
    Nostrum.Consumer.start_link(__MODULE__)
  end

  defp error_message(message) do
    Api.create_message(message, %{
      embed: %{
        Util.begin_embed(:error)
        | title: "Error",
          description:
            "Sorry, something went wrong. Please try again or contact the bot admin if this issue persists."
      }
    })
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.message_create()) :: any()
  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    unless message.author.bot do
      with {:ok, _, _, _, _, _} <- Command.Parser.prefix(message.content) do
        case Command.dispatch(message) do
          {:error, reason} ->
            throw(reason)

          {:prederr, reason} ->
            {:ok, _} =
              Api.create_message(message, %{
                embed: %{
                  Util.begin_embed(:error)
                  | title: "Error",
                    description: "Sorry, #{reason}."
                }
              })

          {:noperm, reason} ->
            {:ok, _} =
              Api.create_message(message, %{
                embed: %{
                  Util.begin_embed(:error)
                  | title: "Error",
                    description: "Sorry, #{reason}."
                }
              })

          :noshow ->
            :ok = Command.Invalid.execute([], message)

          _ ->
            :ok
        end
      end
    end
  rescue
    e ->
      Logger.warning(Exception.format(:error, e, __STACKTRACE__))
      {:ok, _} = error_message(message)
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.ready()) :: any()
  def handle_event({:READY, data, _ws_state}) do
    :ok = CommandRegistry.load_commands()
    me = Nostrum.Cache.Me.get()
    n_guilds = length(data.guilds)

    Logger.info(
      "Pencil.Discord is up and running! Now serving #{n_guilds} guild#{unless n_guilds == 1, do: "s", else: ""} as `#{me.username}##{me.discriminator}`."
    )

    :ok
  end

  def handle_event(_), do: :noop
end
