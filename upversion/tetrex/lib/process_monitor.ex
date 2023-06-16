defmodule ProcessMonitor do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def monitor(handle_exit) when is_function(handle_exit, 1) do
    GenServer.call(__MODULE__, {:monitor, handle_exit})
  end

  def unmonitor() do
    GenServer.call(__MODULE__, :unmonitor)
  end

  @impl true
  def init(_) do
    {:ok, %{monitored: %{}}}
  end

  @impl true
  def handle_call({:monitor, handle_exit}, {caller_pid, _}, %{monitored: monitored} = state)
      when not is_map_key(monitored, caller_pid) do
    monitor_ref = Process.monitor(caller_pid)

    {:reply, :ok,
     %{state | monitored: Map.put(monitored, caller_pid, {handle_exit, monitor_ref})}}
  end

  @impl true
  def handle_call({:monitor, _handle_exit}, _from, state) do
    {:reply, {:error, :already_monitored}, state}
  end

  @impl true
  def handle_call(:unmonitor, {caller_pid, _}, %{monitored: monitored} = state)
      when is_map_key(monitored, caller_pid) do
    {{_handle_exit, monitor_ref}, new_monitored} = Map.pop(monitored, caller_pid)

    Process.demonitor(monitor_ref)

    {:reply, :ok, %{state | monitored: new_monitored}}
  end

  @impl true
  def handle_call(:unmonitor, _caller_pid, state), do: {:reply, {:error, :not_monitored}, state}

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, %{monitored: monitored} = state) do
    {{handle_exit, _monitor_ref}, new_monitored} = Map.pop(monitored, pid)

    # should wrap in isolated task or rescue from exception
    handle_exit.(reason)
    {:noreply, %{state | monitored: new_monitored}}
  end
end
