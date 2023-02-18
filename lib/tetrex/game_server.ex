defmodule Tetrex.GameServer do
  use GenServer
  alias Tetrex.Periodic
  alias Tetrex.BoardServer
  alias Tetrex.Game

  @board_height 20
  @board_width 10

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

  def new_game(game_server) do
    GenServer.cast(game_server, :new_game)
  end

  def start_game(game_server) do
    GenServer.cast(game_server, :start_game)
  end

  def pause_game(game_server) do
    GenServer.cast(game_server, :pause_game)
  end

  def try_move_down(game_server) do
    GenServer.call(game_server, :try_move_down)
  end

  def drop(game_server) do
    GenServer.call(game_server, :drop)
  end

  def try_move_left(game_server) do
    GenServer.call(game_server, :try_move_left)
  end

  def try_move_right(game_server) do
    GenServer.call(game_server, :try_move_right)
  end

  def hold(game_server) do
    GenServer.cast(game_server, :hold)
  end

  def rotate(game_server) do
    GenServer.cast(game_server, :rotate)
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
       status: :new_game,
       # Unused so far
       player_id: player_id,
       score: 0
     }}
  end

  @impl true
  def handle_call(:get_game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call(
        :try_move_down,
        _from,
        %Game{board_pid: board, lines_cleared: lines_cleared, periodic_mover_pid: periodic} = game
      ) do
    {_move_result, preview, extra_lines_cleared} = BoardServer.try_move_down(board)

    # Reset the move timer so we don't get double moves
    Periodic.reset_timer(periodic)

    game =
      %Game{game | lines_cleared: lines_cleared + extra_lines_cleared}
      |> update_level()
      |> check_game_over(preview)

    {:reply, lines_cleared, game}
  end

  @impl true
  def handle_call(:drop, _from, %Game{board_pid: board, lines_cleared: lines_cleared} = game) do
    {preview, extra_lines_cleared} = BoardServer.drop(board)

    game =
      %Game{game | lines_cleared: lines_cleared + extra_lines_cleared}
      |> update_level()
      |> check_game_over(preview)

    {:reply, lines_cleared, game}
  end

  @impl true
  def handle_call(:try_move_left, _from, %Game{board_pid: board} = game) do
    {move_result, _preview} = BoardServer.try_move_left(board)

    {:reply, move_result, game}
  end

  @impl true
  def handle_call(:try_move_right, _from, %Game{board_pid: board} = game) do
    {move_result, _preview} = BoardServer.try_move_right(board)
    {:reply, move_result, game}
  end

  @impl true
  def handle_cast(:new_game, %Game{periodic_mover_pid: periodic, board_pid: board} = game) do
    Periodic.stop_timer(periodic)

    BoardServer.new(
      board,
      @board_height,
      @board_width,
      Enum.random(0..10_000_000)
    )

    {:noreply, %Game{game | status: :intro}}
  end

  @impl true
  def handle_cast(:start_game, %Game{periodic_mover_pid: periodic} = game) do
    Periodic.start_timer(periodic)

    {:noreply, %Game{game | status: :playing}}
  end

  @impl true
  def handle_cast(:pause_game, %Game{periodic_mover_pid: periodic} = game) do
    Periodic.stop_timer(periodic)

    {:noreply, %Game{game | status: :paused}}
  end

  @impl true
  def handle_cast(:hold, %Game{board_pid: board} = game) do
    BoardServer.hold(board)

    {:noreply, game}
  end

  @impl true
  def handle_cast(:rotate, %Game{board_pid: board} = game) do
    BoardServer.rotate(board)

    {:noreply, game}
  end

  # Internal helper functions

  defp game_over(%Game{periodic_mover_pid: periodic} = game) do
    Periodic.stop_timer(periodic)
    %Game{game | status: :game_over}
  end

  defp check_game_over(game, %{active_tile_fits: false}), do: game_over(game)
  defp check_game_over(game, %{active_tile_fits: true}), do: game

  # TODO: Move into own behaviour module - differs from multi player game
  defp update_level(%Game{lines_cleared: lines_cleared, periodic_mover_pid: periodic} = game) do
    speed =
      lines_cleared
      |> level()
      |> level_speed()

    Periodic.set_period(periodic, floor(speed * 1000))

    game
  end

  defp level(lines_cleared) do
    div(lines_cleared, 10)
  end

  defp level_speed(level) do
    # For explanation see: https://tetris.fandom.com/wiki/Tetris_(NES,_Nintendo)
    frames_per_gridcell =
      case level do
        0 -> 48
        1 -> 43
        2 -> 38
        3 -> 33
        4 -> 28
        5 -> 23
        6 -> 18
        7 -> 13
        8 -> 8
        9 -> 6
        _ when 10 <= level and level <= 12 -> 5
        _ when 13 <= level and level <= 15 -> 4
        _ when 16 <= level and level <= 18 -> 3
        _ when 19 <= level and level <= 28 -> 2
        _ -> 1
      end

    frames_per_gridcell / 60
  end
end
