defmodule Pencil.Core.Wrapper do
  use GenServer

  require Logger

  alias Phoenix.PubSub

  @spec start(Keyword.t()) :: any
  def start(opts) do
    GenServer.start(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  @spec init(Keyword.t()) :: {:ok, {port, reference}}
  def init(kw) do
    Process.flag(:trap_exit, true)
    {:ok, start_server(kw)}
  end

  defp start_server(kw) do
    wrapper_bin = Path.expand(Keyword.get(kw, :wrapper_bin))
    java_bin = Keyword.get(kw, :java_bin, System.find_executable("java"))

    jvm_args = Keyword.get(kw, :jvm_args, [])
    server_args = Keyword.get(kw, :server_args, [])
    server_jar = Keyword.get(kw, :jar, "server.jar")

    args = List.flatten([java_bin, jvm_args, "-jar", server_jar, server_args])

    port =
      Port.open({:spawn_executable, wrapper_bin}, [
        :stream,
        :binary,
        :stderr_to_stdout,
        args: args,
        cd: "./run"
      ])

    ref = Port.monitor(port)

    {port, ref}
  end

  @impl true
  def handle_info({port, msg}, {_, ref}) when is_port(port) do
    handle_port(msg, port, ref)
  end

  @impl true
  def handle_info({:DOWN, ref, :port, port, reason}, {_, _}) do
    {:stop, {:shutdown, {:server_down, reason}}, {port, ref}}
  end

  @impl true
  def handle_info({:EXIT, _port, :normal}, state), do: {:noreply, state}

  def handle_port({:data, out}, port, ref) do
    out = String.trim_trailing(out, "\n")

    cond do
      String.contains?(out, "WARN") ->
        Logger.warn(out)
        PubSub.broadcast!(:pencil, "server_status:log", {:warn, out})

      String.contains?(out, "ERROR") ->
        Logger.error(out)
        PubSub.broadcast!(:pencil, "server_status:log", {:error, out})

      String.contains?(out, "FATAL") ->
        Logger.critical(out)
        PubSub.broadcast!(:pencil, "server_status:log", {:fatal, out})

      true ->
        Logger.info(out)
        PubSub.broadcast!(:pencil, "server_status:log", {:info, out})

        if String.match?(out, ~R"INFO\]: Done \((.*)\)! For help, type \"help\"") do
          PubSub.broadcast!(:pencil, "server_status", :started)
        end
    end

    {:noreply, {port, ref}}
  end

  @impl true
  def terminate(_, {port, _}) do
    if not is_nil(Port.info(port)) do
      Port.close(port)
    end
  end
end
