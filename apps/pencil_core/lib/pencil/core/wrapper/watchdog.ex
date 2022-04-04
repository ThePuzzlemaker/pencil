defmodule Pencil.Core.Wrapper.Watchdog do
  use GenServer, restart: :transient

  require Logger

  alias Phoenix.PubSub

  @max_restarts 3
  @max_seconds 5 * 60

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Process.flag(:trap_exit, true)
    {:ok, restart(%{process: nil, ref: nil, crash_times: []})}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _process, reason}, state) do
    now = Time.utc_now()
    crash_times = Map.get(state, :crash_times)

    within_window = Enum.reject(crash_times, &(Time.diff(now, &1) >= @max_seconds))

    if length(within_window) > @max_restarts do
      {:stop, {:shutdown, {:restart_loop, reason}}, state}
    else
      if length(within_window) == 0 do
        PubSub.broadcast!(:pencil, "server_status", :crash)
      end

      {:noreply, restart(%{state | crash_times: [now | within_window]})}
    end
  end

  @impl true
  def terminate({:shutdown, {:restart_loop, reason}}, _state) do
    Logger.debug("Server entered restart loop: #{inspect(reason)}")
    PubSub.broadcast!(:pencil, "server_status", :permacrash)
  end

  @impl true
  def terminate(reason, %{process: process, ref: ref}) do
    if Process.alive?(process) do
      Process.demonitor(ref)
      Process.exit(process, reason)
    end

    reason
  end

  defp restart(state) do
    prev_ref = Map.get(state, :ref)

    if not is_nil(prev_ref) do
      Process.demonitor(prev_ref)
    end

    {:ok, process} = Pencil.Core.Wrapper.start(Application.fetch_env!(:pencil_core, :minecraft))
    ref = Process.monitor(process)
    %{state | process: process, ref: ref}
  end
end
