defmodule Tetrex.GameServer do
  use GenServer
  alias Tetrex.BoardServer
  alias Tetrex.Game

  # Client API

  def start_link(opts \\ []) do
    # TODO: Pass in player ID
    GenServer.start_link(__MODULE__, [player_id: 1], opts)
  end

  def start(opts \\ []) do
    # TODO: Pass in player ID
    GenServer.start(__MODULE__, [player_id: 1], opts)
  end

  def game(game_server) do
    GenServer.call(game_server, :get_game)
  end

  def update_lines_cleared(game_server, update_fn) when is_function(update_fn, 1) do
    GenServer.cast(game_server, {:update_lines_cleared, update_fn})
  end

  def set_status(game_server, status) when status in [:intro, :playing, :game_over] do
    GenServer.cast(game_server, {:set_status, status})
  end

  # Server callbacks

  @impl true
  def init(opts) do
    player_id = Keyword.fetch!(opts, :player_id)

    {:ok, board_server_pid} = BoardServer.start_link([])

    # Create a periodic task to move the piece down
    {:ok, periodic_mover_pid} =
      Tetrex.Periodic.start_link(
        [
          period_ms: 1000,
          start: false,
          work: fn -> nil end
        ],
        []
      )

    {:ok,
     %Game{
       board_pid: board_server_pid,
       periodic_mover_pid: periodic_mover_pid,
       lines_cleared: 0,
       # Unused so far
       score: 0,
       player_id: player_id,
       status: :new_game
     }}
  end

  @impl true
  def handle_call(:get_game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_cast(
        {:update_lines_cleared, update_fn},
        %Game{lines_cleared: lines_cleared} = game
      ) do
    {:noreply, %Game{game | lines_cleared: update_fn.(lines_cleared)}}
  end

  @impl true
  def handle_cast({:set_status, status}, game) do
    {:noreply, %Game{game | status: status}}
  end
end
