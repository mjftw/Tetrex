defmodule CarsCommercePuzzleAdventure.Periodic do
  use GenServer

  # Client API
  def start_link(init_args, opts) do
    GenServer.start_link(__MODULE__, init_args, opts)
  end

  def start_timer(pid), do: GenServer.cast(pid, :start_timer)

  def stop_timer(pid), do: GenServer.cast(pid, :stop_timer)

  def reset_timer(pid), do: GenServer.cast(pid, :reset_timer)

  def set_period(pid, period_ms) when is_integer(period_ms),
    do: GenServer.cast(pid, {:set_period, period_ms})

  def set_work(pid, work) when is_function(work), do: GenServer.cast(pid, {:set_work, work})

  # Server code
  @impl true
  def init(args) do
    period_ms = Keyword.fetch!(args, :period_ms)
    work = Keyword.fetch!(args, :work)
    start = Keyword.get(args, :start, false)

    state = %{
      period_ms: period_ms,
      work: work,
      timer_ref: nil
    }

    if start do
      {:ok, state, {:continue, :start_timer}}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_continue(:start_timer, %{period_ms: period_ms, timer_ref: timer_ref} = state) do
    cancel_timer(timer_ref)

    timer_ref = Process.send_after(self(), :send, period_ms)

    {:noreply, %{state | timer_ref: timer_ref}}
  end

  @impl true
  def handle_info(:send, %{work: work} = state) do
    work.()

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
    {:noreply, state, {:continue, :start_timer}}
  end

  @impl true
  def handle_cast(:stop_timer, %{timer_ref: timer_ref} = state) do
    cancel_timer(timer_ref)

    {:noreply, %{state | timer_ref: nil}}
  end

  @impl true
  def handle_cast(:reset_timer, %{timer_ref: timer_ref} = state) do
    cancel_timer(timer_ref)

    {:noreply, %{state | timer_ref: nil}, {:continue, :start_timer}}
  end

  defp cancel_timer(timer_ref) when timer_ref == nil, do: :not_timer
  defp cancel_timer(timer_ref) when timer_ref != nil, do: Process.cancel_timer(timer_ref)
end
