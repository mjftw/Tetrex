defmodule Tetrex.Tick do
  use GenServer

  # Client API
  def start_link(init_args, opts) do
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  # Server code
  @impl true
  def init(args) do
    period_ms = Keyword.fetch!(args, :period_ms)
    msg = Keyword.fetch!(args, :msg)
    to = Keyword.fetch!(args, :to)
    running = Keyword.get(args, :start, false)

    {:ok, {period_ms, running, msg, to}, {:continue, :start_timer}}
  end

  @impl true
  def handle_continue(:start_timer, {period_ms, running, _msg, _to} = state) do
    if(running) do
      Process.send_after(self(), :send, period_ms)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:send, {_period_ms, running, msg, to} = state) do
    if(running) do
      Process.send(to, msg, [])
    end

    # Requeue sending the msg by deferring to handle_continue
    {:noreply, state, {:continue, :start_timer}}
  end

  @impl true
  def handle_cast({:set_period, period_ms}, {_period_ms, running, msg, to}) do
    {:noreply, {period_ms, running, msg, to}}
  end

  @impl true
  def handle_cast(:start, {period_ms, _running, msg, to}) do
    {:noreply, {period_ms, true, msg, to}, {:continue, :start_timer}}
  end

  @impl true
  def handle_cast(:stop, {period_ms, _running, msg, to}) do
    {:noreply, {period_ms, false, msg, to}}
  end
end
