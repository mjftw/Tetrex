defmodule Tetrex.Periodic do
  use GenServer

  # Client API
  def start_link(init_args, opts) do
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  def start_timer(pid), do: GenServer.cast(pid, :start_timer)

  def stop_timer(pid), do: GenServer.cast(pid, :stop_timer)

  def set_period(pid), do: GenServer.cast(pid, :set_period)

  def set_work(pid), do: GenServer.cast(pid, :set_work)

  # Server code
  @impl true
  def init(args) do
    period_ms = Keyword.fetch!(args, :period_ms)
    work = Keyword.fetch!(args, :work)
    running = Keyword.get(args, :start, false)

    {:ok,
     %{
       period_ms: period_ms,
       running: running,
       work: work
     }, {:continue, :start_timer}}
  end

  @impl true
  def handle_continue(:start_timer, %{period_ms: period_ms, running: running} = state) do
    if running do
      Process.send_after(self(), :send, period_ms)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:send, %{running: running, work: work} = state) do
    if(running) do
      work.()
    end

    # Requeue sending the msg by deferring to handle_continue
    {:noreply, state, {:continue, :start_timer}}
  end

  @impl true
  def handle_cast({:set_period, period_ms}, state) do
    {:noreply, %{state | period_ms: period_ms}}
  end

  @impl true
  def handle_cast({:set_work, work}, state)
      when is_function(work, 0) do
    {:noreply, %{state | work: work}}
  end

  @impl true
  def handle_cast(:start_timer, state) do
    {:noreply, %{state | running: true}, {:continue, :start_timer}}
  end

  @impl true
  def handle_cast(:stop_timer, state) do
    {:noreply, %{state | running: false}}
  end
end
