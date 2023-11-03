defmodule CarsCommercePuzzleAdventure.SinglePlayer.GameServer do
  use GenServer
  alias CarsCommercePuzzleAdventure.Periodic
  alias CarsCommercePuzzleAdventure.BoardServer
  alias CarsCommercePuzzleAdventure.SinglePlayer.Game
  alias CarsCommercePuzzleAdventure.SinglePlayer.GameMessage

  @board_height 20
  @board_width 10

  # Client API

  def start_link(user_id: user_id) do
    GenServer.start_link(__MODULE__, [user_id: user_id], [])
  end

  def game(game_server) do
    GenServer.call(game_server, :get_game)
  end

  def game_user_id(game_server) do
    %Game{user_id: user_id} = GenServer.call(game_server, :get_game)
    user_id
  end

  def board_preview(game_server) do
    GenServer.call(game_server, :board_preview)
  end

  def update_lines_cleared(game_server, update_fn) when is_function(update_fn, 1) do
    GenServer.cast(game_server, {:update_lines_cleared, update_fn})
  end

  def new_game(game_server, start_game \\ false) do
    GenServer.cast(game_server, {:new_game, start_game})
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

  def pubsub_topic(user_id), do: "single-player-game:#{user_id}"

  def subscribe_updates(game_server),
    do:
      Phoenix.PubSub.subscribe(
        CarsCommercePuzzleAdventure.PubSub,
        game_server
        |> game_user_id()
        |> pubsub_topic()
      )

  # Server callbacks

  @impl true
  def init(user_id: user_id) do
    {:ok, board_server_pid} = BoardServer.start_link([])

    # Create a periodic task to move the piece down
    {:ok, periodic_mover_pid} =
      CarsCommercePuzzleAdventure.Periodic.start_link(
        [
          period_ms: 1000,
          start: false,
          work: fn -> nil end
        ],
        []
      )

    {:ok,
     %Game{
       user_id: user_id,
       board_pid: board_server_pid,
       periodic_mover_pid: periodic_mover_pid,
       lines_cleared: 0,
       status: :intro
     }, {:continue, :init_periodic}}
  end

  @impl true
  def handle_continue(
        :publish_state,
        %Game{
          board_pid: board_pid,
          lines_cleared: lines_cleared,
          status: status,
          user_id: user_id
        } = game
      ) do
    board_preview = BoardServer.preview(board_pid)

    game_update = %GameMessage{
      game_pid: self(),
      lines_cleared: lines_cleared,
      status: status,
      board_preview: board_preview
    }

    Phoenix.PubSub.broadcast!(CarsCommercePuzzleAdventure.PubSub, pubsub_topic(user_id), game_update)

    {:noreply, game}
  end

  @impl true
  def handle_continue(:init_periodic, %Game{periodic_mover_pid: periodic_mover_pid} = game) do
    this_game_server = self()

    # Set the periodic task to move the piece down
    CarsCommercePuzzleAdventure.Periodic.set_work(periodic_mover_pid, fn ->
      try_move_down(this_game_server)
    end)

    {:noreply, game}
  end

  @impl true
  def handle_call(:get_game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call(:board_preview, _from, %Game{board_pid: board} = game) do
    preview = BoardServer.preview(board)

    {:reply, preview, game}
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

    {:reply, lines_cleared, game, {:continue, :publish_state}}
  end

  @impl true
  def handle_call(:drop, _from, %Game{board_pid: board, lines_cleared: lines_cleared} = game) do
    {preview, extra_lines_cleared} = BoardServer.drop(board)

    game =
      %Game{game | lines_cleared: lines_cleared + extra_lines_cleared}
      |> update_level()
      |> check_game_over(preview)

    {:reply, lines_cleared, game, {:continue, :publish_state}}
  end

  @impl true
  def handle_call(:try_move_left, _from, %Game{board_pid: board} = game) do
    {move_result, _preview} = BoardServer.try_move_left(board)

    {:reply, move_result, game, {:continue, :publish_state}}
  end

  @impl true
  def handle_call(:try_move_right, _from, %Game{board_pid: board} = game) do
    {move_result, _preview} = BoardServer.try_move_right(board)
    {:reply, move_result, game, {:continue, :publish_state}}
  end

  @impl true
  def handle_cast(
        {:new_game, false},
        %Game{periodic_mover_pid: periodic, board_pid: board} = game
      ) do
    Periodic.stop_timer(periodic)

    BoardServer.new(
      board,
      @board_height,
      @board_width,
      Enum.random(0..10_000_000)
    )

    {:noreply, %Game{game | lines_cleared: 0, status: :intro}, {:continue, :publish_state}}
  end

  @impl true
  def handle_cast(
        {:new_game, true},
        %Game{periodic_mover_pid: periodic, board_pid: board} = game
      ) do
    Periodic.start_timer(periodic)

    BoardServer.new(
      board,
      @board_height,
      @board_width,
      Enum.random(0..10_000_000)
    )

    {:noreply, %Game{game | lines_cleared: 0, status: :playing}, {:continue, :publish_state}}
  end

  @impl true
  def handle_cast(:start_game, %Game{periodic_mover_pid: periodic} = game) do
    Periodic.start_timer(periodic)

    {:noreply, %Game{game | status: :playing}, {:continue, :publish_state}}
  end

  @impl true
  def handle_cast(:pause_game, %Game{periodic_mover_pid: periodic} = game) do
    Periodic.stop_timer(periodic)

    {:noreply, %Game{game | status: :paused}, {:continue, :publish_state}}
  end

  @impl true
  def handle_cast(:hold, %Game{board_pid: board} = game) do
    BoardServer.hold(board)

    {:noreply, game, {:continue, :publish_state}}
  end

  @impl true
  def handle_cast(:rotate, %Game{board_pid: board} = game) do
    BoardServer.rotate(board)

    {:noreply, game, {:continue, :publish_state}}
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
    # For explanation see: https://puzzle_adventure.fandom.com/wiki/PuzzleAdventure_(NES,_Nintendo)
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

  defp game_id, do: self()
end
