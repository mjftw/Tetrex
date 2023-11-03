defmodule CarsCommercePuzzleAdventure.Multiplayer.GameServer do
  alias CarsCommercePuzzleAdventure.Periodic
  alias CarsCommercePuzzleAdventure.BoardServer
  alias CarsCommercePuzzleAdventure.Multiplayer.Game
  use GenServer

  require Logger

  @num_fake_players_to_add_on_start Application.compile_env(
                                      :cars_commerce_puzzle_adventure,
                                      [
                                        :settings,
                                        :multiplayer,
                                        :num_fake_players_to_add_on_start
                                      ],
                                      0
                                    )
  @use_multiplayer_state_diff Application.compile_env(
                                :cars_commerce_puzzle_adventure,
                                [
                                  :settings,
                                  :multiplayer,
                                  :use_multiplayer_state_diff
                                ],
                                false
                              )

  @send_blocking_row_probability Application.compile_env(
                                   :cars_commerce_puzzle_adventure,
                                   [
                                     :settings,
                                     :multiplayer,
                                     :send_blocking_row_probability
                                   ],
                                   0.5
                                 )
  @rate_limit_max_updates_per_sec Application.compile_env(
                                    :cars_commerce_puzzle_adventure,
                                    [
                                      :settings,
                                      :multiplayer,
                                      :rate_limit_max_updates_per_sec
                                    ],
                                    30
                                  )

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

  def kill_player(game_server, user_id) do
    GenServer.call(game_server, {:kill_player, user_id})
  end

  def try_move_down(game_server, user_id) do
    GenServer.call(game_server, {:try_move_down, user_id})
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
      CarsCommercePuzzleAdventure.PubSub,
      pubsub_topic(game_id)
    )
  end

  def unsubscribe_updates(game_server) do
    game_id = get_game_id(game_server)

    Phoenix.PubSub.unsubscribe(
      CarsCommercePuzzleAdventure.PubSub,
      pubsub_topic(game_id)
    )
  end

  def get_game_message(game_server) do
    GenServer.call(game_server, :game_message)
  end

  def increase_game_level(game_server, level) do
    GenServer.cast(game_server, {:increase_game_level, level})
  end

  def force_start(game_server) do
    GenServer.cast(game_server, :force_start)
  end

  def pubsub_topic(game_id), do: "multiplayer-game:#{game_id}"

  @impl true
  def init(_opts) do
    # This will set the Periodic mover timer for all new players that join.
    #  It will be updated as the game progresses
    initial_push_down_period_ms = 1000

    {:ok, Game.new(initial_push_down_period_ms), {:continue, :begin_publish_loop}}
  end

  @impl true
  def handle_continue(:begin_publish_loop, game) do
    Process.send(self(), :publish_state_loop, [])
    {:noreply, game}
  end

  @impl true
  # If all players have left or died, kill the game server after publishing state
  def handle_info(:publish_state_loop, game) do
    game =
      if !Game.new?(game) && Game.num_alive_players(game) == 0 do
        Game.set_exiting(game)
      else
        game
      end

    if @use_multiplayer_state_diff do
      {game, patch} = Game.publish_message_patch(game)
      # Publish patch if possible, otherwise publish entire state
      case patch do
        nil -> publish_state(game)
        patch -> publish_patch(game, patch)
      end
    else
      publish_state(game)
    end

    if Game.exiting?(game) do
      {:noreply, game}
    else
      Process.send_after(self(), :publish_state_loop, div(1000, @rate_limit_max_updates_per_sec))
      {:noreply, game}
    end
  end

  @impl true
  def handle_continue(:request_termination, %Game{game_id: game_id}) do
    CarsCommercePuzzleAdventure.GameDynamicSupervisor.remove_multiplayer_game_by_pid(self(), game_id)

    # Do not return, await termination
    Process.sleep(:infinity)
  end

  @impl true
  def handle_cast({:increase_game_level, level}, game) do
    game = update_level_speed(game, level)
    {:noreply, game}
  end

  @impl true
  def handle_cast(:force_start, game) do
    {:noreply, start_game(game)}
  end

  @impl true
  def handle_call({:try_move_down, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid, periodic_mover_pid: periodic_mover_pid}} ->
        {_status, _new_board, num_lines_cleared} = BoardServer.try_move_down(board_pid)

        Periodic.reset_timer(periodic_mover_pid)

        game = update_game_after_player_moved_down(game, user_id, board_pid, num_lines_cleared)

        {:reply, :ok, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:drop, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        {_, num_lines_cleared} = BoardServer.drop(board_pid)

        game = update_game_after_player_moved_down(game, user_id, board_pid, num_lines_cleared)

        {:reply, :ok, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:try_move_left, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.try_move_left(board_pid)
        {:reply, :ok, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:try_move_right, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.try_move_right(board_pid)
        {:reply, :ok, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:hold, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.hold(board_pid)
        {:reply, :ok, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:rotate, user_id}, _from, game) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        BoardServer.rotate(board_pid)
        {:reply, :ok, game}

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
        game
      ) do
    if Game.player_in_game?(game, user_id) do
      {:reply, {:error, :already_in_game}, game}
    else
      game = do_join_game(game, user_id)

      {:reply, :ok, game}
    end
  end

  @impl true
  def handle_call({:leave_game, user_id}, _from, game) do
    if Game.players_can_leave?(game) do
      case Game.get_player_state(game, user_id) do
        {:ok, %{board_pid: board_pid, periodic_mover_pid: periodic_mover_pid}} ->
          # Kill board & periodic process as no longer required
          Process.unlink(board_pid)
          Process.exit(board_pid, :kill)
          Process.unlink(periodic_mover_pid)
          Process.exit(periodic_mover_pid, :kill)

          game = Game.drop_player(game, user_id)

          {:reply, :ok, game}

        {:error, error} ->
          {:reply, {:error, error}, game}
      end
    else
      {:reply, {:error, :cannot_leave_game_in_progress}, game}
    end
  end

  @impl true
  def handle_call({:set_player_ready, user_id, is_ready?}, _from, game) do
    case Game.set_player_ready(game, user_id, is_ready?) do
      {:ok, game} ->
        game = if Game.ready_to_start?(game), do: start_game(game), else: game

        {:reply, :ok, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  @impl true
  def handle_call({:kill_player, user_id}, _from, game) do
    case kill_player_stop_timer(game, user_id) do
      {:ok, game} ->
        game = finish_game_if_required(game)
        {:reply, :ok, game}

      {:error, error} ->
        {:reply, {:error, error}, game}
    end
  end

  defp publish_state(%Game{game_id: game_id} = game) do
    Phoenix.PubSub.broadcast!(
      CarsCommercePuzzleAdventure.PubSub,
      pubsub_topic(game_id),
      Game.to_game_message(game)
    )
  end

  defp publish_patch(%Game{game_id: game_id}, patch) do
    Phoenix.PubSub.broadcast!(
      CarsCommercePuzzleAdventure.PubSub,
      pubsub_topic(game_id),
      patch
    )
  end

  defp update_level_speed(%Game{players: players, level: current_level} = game, min_level \\ 0) do
    # The player with the most lines cleared sets the game speed
    # unless the level is already higher

    highest_level =
      players
      |> Stream.map(fn {_user_id, %{lines_cleared: lines_cleared}} -> lines_cleared end)
      |> Enum.max()
      |> level()

    new_level =
      current_level
      |> max(highest_level)
      |> max(min_level)

    speed = level_speed(new_level)

    period_ms = floor(speed * 1000)

    players
    |> Stream.map(fn {_user_id, %{periodic_mover_pid: periodic_mover_pid}} ->
      Task.async(fn -> Periodic.set_period(periodic_mover_pid, period_ms) end)
    end)
    |> Enum.each(&Task.await/1)

    %Game{game | level: new_level}
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

  defp start_game(game) do
    dbg_num_fake_players = @num_fake_players_to_add_on_start

    game =
      if dbg_num_fake_players > 0 do
        dbg_add_ready_players(game, dbg_num_fake_players)
      else
        game
      end

    game.players
    |> Stream.map(fn {_user_id, %{periodic_mover_pid: periodic_mover_pid}} ->
      Task.async(fn -> Periodic.start_timer(periodic_mover_pid) end)
    end)
    |> Enum.each(&Task.await/1)

    Game.start(game)
  end

  defp do_join_game(%Game{periodic_timer_period: periodic_timer_period} = game, user_id) do
    {:ok, board_pid} = BoardServer.start_link()

    this_game_server = self()

    # Must be one Periodic timer per board though as you need to reset the timer
    #   when a player moves a piece down manually, but this must be done on
    # a per player basis.
    {:ok, periodic_mover_pid} =
      CarsCommercePuzzleAdventure.Periodic.start_link(
        [
          period_ms: periodic_timer_period,
          start: false,
          work: fn ->
            try_move_down(this_game_server, user_id)
          end
        ],
        []
      )

    Game.add_player(game, user_id, board_pid, periodic_mover_pid)
  end

  defp update_game_after_player_moved_down(game, user_id, board_pid, num_lines_cleared) do
    %{active_tile_fits: player_still_alive} = BoardServer.preview(board_pid)

    game =
      if num_lines_cleared > 0 do
        update_level_speed(game)
      else
        game
      end

    {:ok, game} = Game.increment_player_lines_cleared(game, user_id, num_lines_cleared)

    {:ok, game} =
      if player_still_alive do
        {:ok, game}
      else
        {:ok, game} = kill_player_stop_timer(game, user_id)
        game = finish_game_if_required(game)
        {:ok, game}
      end

    # Send a blocking row to a random alive player per line cleared
    # Probability of sending a row is == @send_blocking_row_probability
    game =
      game
      |> Game.alive_players()
      |> Stream.map(fn {player_user_id, _} -> player_user_id end)
      |> Stream.filter(fn player_user_id -> player_user_id != user_id end)
      |> Enum.take_random(num_lines_cleared)
      |> Enum.filter(fn _ -> random_bool(@send_blocking_row_probability) end)
      |> Enum.reduce(game, fn user_id, game ->
        case send_blocking_row_to_player(game, user_id) do
          {:ok, new_game} ->
            new_game

          {:error, error} ->
            Logger.error(error)
            game
        end
      end)

    game
  end

  defp finish_game_if_required(%Game{players: players} = game) do
    game = Game.finish_if_required(game)

    if game.status == :finished do
      players
      |> Stream.map(fn {_user_id, %{periodic_mover_pid: periodic_mover_pid}} ->
        Task.async(fn -> Periodic.stop_timer(periodic_mover_pid) end)
      end)
      |> Enum.each(&Task.await/1)
    end

    game
  end

  defp kill_player_stop_timer(game, user_id) do
    with {:ok, %{periodic_mover_pid: periodic_mover_pid}} <- Game.get_player_state(game, user_id),
         {:ok, game} <- Game.kill_player(game, user_id) do
      Periodic.stop_timer(periodic_mover_pid)
      {:ok, game}
    end
  end

  defp send_blocking_row_to_player(game, user_id) do
    case Game.get_player_state(game, user_id) do
      {:ok, %{board_pid: board_pid}} ->
        case BoardServer.add_blocking_row(board_pid) do
          %{active_tile_fits: false} -> kill_player_stop_timer(game, user_id)
          _ -> {:ok, game}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp random_bool(true_probability) do
    :rand.uniform(100) <= true_probability * 100
  end

  # Note this function is only for debug use
  defp dbg_add_ready_players(game, num_players) do
    Enum.reduce(1..num_players, game, fn _, game ->
      id = UUID.uuid1()

      {:ok, game} =
        game
        |> do_join_game(id)
        |> Game.set_player_ready(id, true)

      game
    end)
  end
end
