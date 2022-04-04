defmodule Pencil.Discord.Command.Predicate do
  alias Nostrum.Struct.{Message, User}

  @type result() :: :next | {:noperm, String.t()} | {:prederr, String.t()} | :noshow

  @type t() :: (Message.t() -> result())

  @spec evaluate(Message.t(), [t()]) :: result()
  def evaluate(message, predicates) do
    predicates
    |> Stream.map(& &1.(message))
    |> Enum.find(
      :next,
      &(match?({kind, _} when kind in [:prederr, :noperm], &1) || &1 == :noshow)
    )
  end

  def guild_only(%Message{guild_id: nil}),
    do: {:prederr, "this command can only be used in guilds"}

  def guild_only(_), do: :next

  def is_superuser?(%Message{author: %User{id: id}}) do
    env = Application.get_env(:pencil_discord, :bot)

    if id in Keyword.get(env, :superusers) do
      :next
    else
      {:noperm, "only bot admins can run this command"}
    end
  end

  def is_superuser?(_), do: {:noperm, "only bot admins can run this command"}

  defmacro noshow_of(predicate) do
    quote location: :keep, bind_quoted: [predicate: predicate] do
      fn msg ->
        predicate.(msg)
        :noshow
      end
    end
  end
end
