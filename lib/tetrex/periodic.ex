defmodule Tetrex.Periodic do
  use GenServer

  # Client API
  def start_link(init_args, opts) do
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  # Server code
  @impl true
  def init(args) do
    period_ms = Keyword.fetch!(args, :period_ms)
    work = Keyword.fetch!(args, :work)
    running = Keyword.get(args, :start, false)

    {:ok, {period_ms, running, work}, {:continue, :start_timer}}
  end

  @impl true
  def handle_continue(:start_timer, {period_ms, running, _work} = state) do
    if(running) do
      Process.send_after(self(), :send, period_ms)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:send, {_period_ms, running, work} = state) do
    if(running) do
      work.()
    end

    # Requeue sending the msg by deferring to handle_continue
    {:noreply, state, {:continue, :start_timer}}
  end

  @impl true
  def handle_cast({:set_period, period_ms}, {_period_ms, running, work}) do
    {:noreply, {period_ms, running, work}}
  end

  @impl true
  def handle_cast({:set_work, work}, {period_ms, running, _work}) when is_function(work, 0) do
    {:noreply, {period_ms, running, work}}
  end

  @impl true
  def handle_cast(:start, {period_ms, _running, work}) do
    {:noreply, {period_ms, true, work}, {:continue, :start_timer}}
  end

  @impl true
  def handle_cast(:stop, {period_ms, _running, work}) do
    {:noreply, {period_ms, false, work}}
  end
end
