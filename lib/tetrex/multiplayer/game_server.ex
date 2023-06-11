defmodule Tetrex.Multiplayer.GameServer do
  alias Tetrex.Periodic
  alias Tetrex.BoardServer
  alias Tetrex.Multiplayer.Game
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def get_game_id(game_server) do
    GenServer.call(game_server, :get_game_id)
  end

  def game(game_server) do
    GenServer.call(game_server, :game)
  end

  def join_game(game_server, user_id) do
    GenServer.call(game_server, {:join_game, user_id})
  end

  def leave_game(game_server, user_id) do
    GenServer.call(game_server, {:leave_game, user_id})
  end

  def set_player_ready(game_server, user_id, is_ready?) do
    GenServer.call(game_server, {:set_player_ready, user_id, is_ready?})
  end

  def move_all_games_down(game_server) do
    GenServer.cast(game_server, :move_all_boards_down)
  end

  def try_move_down(game_server, user_id) do
    GenServer.call(game_server, {:try_move_down, user_id})
  end

  def try_move_all_down(game_server) do
    GenServer.call(game_server, :try_move_all_down)
  end

  def drop(game_server, user_id) do
    GenServer.call(game_server, {:drop, user_id})
  end

  def try_move_left(game_server, user_id) do
    GenServer.call(game_server, {:try_move_left, user_id})
  end

  def try_move_right(game_server, user_id) do
    GenServer.call(game_server, {:try_move_right, user_id})
  end

  def hold(game_server, user_id) do
    GenServer.call(game_server, {:hold, user_id})
  end

  def rotate(game_server, user_id) do
    GenServer.call(game_server, {:rotate, user_id})
  end

  def subscribe_updates(game_server) do
    game_id = get_game_id(game_server)

    Phoenix.PubSub.subscribe(
      Tetrex.PubSub,
      pubsub_topic(game_id)
    )
  end

  def unsubscribe_updates(game_server) do
    game_id = get_game_id(game_server)

    Phoenix.PubSub.unsubscribe(
      Tetrex.PubSub,
      pubsub_topic(game_id)
    )
  end

  def get_game_message(game_server) do
    GenServer.call(game_server, :game_message)
  end

  def pubsub_topic(game_id), do: "multiplayer-game:#{game_id}"

  @impl true
  def init(_opts) do
    # This will set the Periodic mover timer for all new players that join.
    #  It will be updated as the game progresses
    initial_push_down_period_ms = 1000

    {:ok, Game.new(initial_push_down_period_ms)}
  end

  @impl true
  def handle_continue(:publish_state, game) do
    publish_update(game)

    {:noreply, game}
  end

  @impl true
  def handle_call({:try_move_down, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid, periodic_mover_pid: periodic_mover_pid}} ->
        {_status, _new_board, num_lines_cleared} = BoardServer.try_move_down(board_pid)

        Periodic.reset_timer(periodic_mover_pid)

        game = update_game_after_player_moved_down(game, user_id, board_pid, num_lines_cleared)

        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call(:try_move_all_down, _from, %Game{players: players} = game) do
    {game, total_lines_cleared} =
      players
      |> Stream.map(fn {user_id, %{board_pid: board_pid}} -> {user_id, board_pid} end)
      |> Stream.map(fn {user_id, board_pid} ->
        Task.async(fn -> {user_id, BoardServer.try_move_down(board_pid)} end)
      end)
      |> Stream.map(&Task.await/1)
      |> Enum.reduce({game, 0}, fn {user_id,
                                    {_status, %{active_tile_fits: player_still_alive},
                                     num_lines_cleared}},
                                   {game, total_lines_cleared} ->
        {:ok, game} = Game.increment_player_lines_cleared(game, user_id, num_lines_cleared)

        {:ok, game} =
          if player_still_alive do
            {:ok, game}
          else
            {:ok, game} = kill_player(game, user_id)
          end

        {game, total_lines_cleared + num_lines_cleared}
      end)

    if total_lines_cleared > 0 do
      update_level_speed(game)
    end

    game = finish_game_if_required(game)

    {:reply, :ok, game, {:continue, :publish_state}}
  end

  @impl true
  def handle_call({:drop, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        {_, num_lines_cleared} = BoardServer.drop(board_pid)

        game = update_game_after_player_moved_down(game, user_id, board_pid, num_lines_cleared)

        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:try_move_left, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.try_move_left(board_pid)
        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:try_move_right, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.try_move_right(board_pid)
        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:hold, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.hold(board_pid)
        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:rotate, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.rotate(board_pid)
        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call(:get_game_id, _from, %Game{game_id: game_id} = game) do
    {:reply, game_id, game}
  end

  @impl true
  def handle_call(:game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call(:game_message, _from, game) do
    {:reply, Game.to_game_message(game), game}
  end

  @impl true
  def handle_call(
        {:join_game, user_id},
        _from,
        %Game{periodic_timer_period: periodic_timer_period} = game
      ) do
    if Game.player_in_game?(game, user_id) do
      {:reply, {:error, :already_in_game}, game}
    else
      {:ok, board_pid} = BoardServer.start_link()

      this_game_server = self()

      # Must be one Periodic timer per board though as you need to reset the timer
      #   when a player moves a piece down manually, but this must be done on
      # a per player basis.
      {:ok, periodic_mover_pid} =
        Tetrex.Periodic.start_link(
          [
            period_ms: periodic_timer_period,
            start: false,
            work: fn ->
              try_move_down(this_game_server, user_id)
            end
          ],
          []
        )

      game = Game.add_player(game, user_id, board_pid, periodic_mover_pid)

      {:reply, :ok, game, {:continue, :publish_state}}
    end
  end

  @impl true
  def handle_call({:leave_game, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid, periodic_mover_pid: periodic_mover_pid}} ->
        # Kill board & periodic process as no longer required
        Process.unlink(board_pid)
        Process.exit(board_pid, :kill)
        Process.unlink(periodic_mover_pid)
        Process.exit(periodic_mover_pid, :kill)

        game = Game.drop_player(game, user_id)

        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:set_player_ready, user_id, is_ready?}, _from, game) do
    case Game.set_player_ready(game, user_id, is_ready?) do
      {:ok, game} ->
        game = if Game.ready_to_start?(game), do: start_game(game), else: game

        {:reply, :ok, game, {:continue, :publish_state}}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  defp publish_update(%Game{game_id: game_id} = game) do
    Phoenix.PubSub.broadcast!(
      Tetrex.PubSub,
      pubsub_topic(game_id),
      Game.to_game_message(game)
    )
  end

  defp update_level_speed(%Game{players: players}) do
    # The player with the mst lines cleared sets the game speed

    speed =
      players
      |> Enum.map(fn {_user_id, %{lines_cleared: lines_cleared}} -> lines_cleared end)
      |> Enum.max()
      |> level()
      |> level_speed()

    period_ms = floor(speed * 1000)

    players
    |> Stream.map(fn {_user_id, %{periodic_mover_pid: periodic_mover_pid}} ->
      Task.async(fn -> Periodic.set_period(periodic_mover_pid, period_ms) end)
    end)
    |> Enum.map(&Task.await/1)
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

  defp start_game(%Game{players: players} = game) do
    players
    |> Stream.map(fn {_user_id, %{periodic_mover_pid: periodic_mover_pid}} ->
      Task.async(fn -> Periodic.start_timer(periodic_mover_pid) end)
    end)
    |> Enum.map(&Task.await/1)

    Game.start(game)
  end

  defp update_game_after_player_moved_down(game, user_id, board_pid, num_lines_cleared) do
    %{active_tile_fits: player_still_alive} = BoardServer.preview(board_pid)

    if num_lines_cleared > 0 do
      update_level_speed(game)
    end

    {:ok, game} = Game.increment_player_lines_cleared(game, user_id, num_lines_cleared)

    {:ok, game} =
      if player_still_alive do
        {:ok, game}
      else
        {:ok, game} = kill_player(game, user_id)
        {:ok, finish_game_if_required(game)}
      end

    game
  end

  defp finish_game_if_required(%Game{players: players} = game) do
    game = Game.finish_if_required(game)

    if game.status == :finished do
      players
      |> Stream.map(fn {_user_id, %{periodic_mover_pid: periodic_mover_pid}} ->
        Task.async(fn -> Periodic.stop_timer(periodic_mover_pid) end)
      end)
      |> Enum.map(&Task.await/1)
    end

    game
  end

  defp kill_player(game, user_id) do
    with {:ok, %{periodic_mover_pid: periodic_mover_pid}} <- Game.get_player_state(game, user_id),
         {:ok, game} <- Game.kill_player(game, user_id) do
      Periodic.stop_timer(periodic_mover_pid)
      {:ok, game}
    end
  end
end
