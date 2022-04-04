defmodule Pencil.Discord.Command.Registry do
  use GenServer

  @handlers ~w(Ping Help CmdReload)

  @spec handler_of(String.t()) :: atom()
  defp handler_of(name), do: String.to_existing_atom("Elixir.Pencil.Discord.Command.#{name}")

  @spec load_commands :: :ok
  def load_commands do
    true =
      :ets.insert(
        __MODULE__,
        Stream.map(@handlers, &handler_of/1)
        |> Stream.map(&{&1.names(), &1})
        |> Stream.flat_map(fn {names, mod} -> for name <- names, do: {name, mod} end)
        |> Enum.to_list()
      )

    :ok
  end

  @spec remove_command(String.t()) :: :ok
  def remove_command(name) do
    true = :ets.delete(__MODULE__, name)
    :ok
  end

  @spec unload_handler(String.t()) :: :ok
  def unload_handler(mod) when is_binary(mod), do: unload_handler(handler_of(mod))

  @spec unload_handler(module()) :: :ok
  def unload_handler(mod) when is_atom(mod) do
    :ets.match(__MODULE__, {:"$1", mod})
    |> List.flatten()
    |> Enum.each(&:ets.delete(__MODULE__, &1))
  end

  @spec load_handler(String.t()) :: :ok
  def load_handler(mod) when is_binary(mod), do: load_handler(handler_of(mod))

  @spec load_handler(module()) :: :ok
  def load_handler(mod) when is_atom(mod) do
    true =
      :ets.insert(
        __MODULE__,
        mod.names() |> Enum.map(&{&1, mod}) |> Enum.to_list()
      )

    :ok
  end

  @spec reload_handler(String.t()) :: :ok
  def reload_handler(mod) when is_binary(mod), do: reload_handler(handler_of(mod))

  @spec reload_handler(module()) :: :ok
  def reload_handler(mod) when is_atom(mod) do
    unload_handler(mod)
    true = :code.soft_purge(mod)
    :code.load_file(mod)
    load_handler(mod)
  end

  @spec lookup(String.t()) :: module | nil
  def lookup(cmd_name) when is_binary(cmd_name) do
    case :ets.lookup(__MODULE__, cmd_name) do
      [] -> nil
      [{_, mod}] -> mod
    end
  end

  @spec all_unique_commands() :: [module]
  def all_unique_commands() do
    :ets.tab2list(__MODULE__) |> Stream.map(fn {_, mod} -> mod end) |> Enum.uniq()
  end

  @spec all_commands() :: %{String.t() => module()}
  def all_commands() do
    :ets.tab2list(__MODULE__)
    |> Enum.reduce(%{}, fn {name, mod}, acc -> Map.put(acc, name, mod) end)
  end

  @spec find_close(String.t(), float()) :: [module]
  def find_close(name, threshold \\ 0.8) do
    :ets.tab2list(__MODULE__)
    |> Enum.filter(fn {test_name, _} -> String.jaro_distance(name, test_name) >= threshold end)
  end

  @spec register(module()) :: :ok
  def register(handler) when is_atom(handler) do
    GenServer.cast(__MODULE__, {:register, handler})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    tid = :ets.new(__MODULE__, [{:read_concurrency, true}, :ordered_set, :public, :named_table])

    {:ok, tid}
  end

  @impl true
  def handle_call(:tid, _, tid) do
    {:reply, tid, tid}
  end
end
