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
       # Unused so far
       lines_cleared: 0,
       score: 0,
       player_id: player_id,
       state: :new_game
     }}
  end

  @impl true
  def handle_call(:get_game, _from, game) do
    {:reply, game, game}
  end
end
