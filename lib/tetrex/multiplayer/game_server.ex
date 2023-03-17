defmodule Tetrex.Multiplayer.GameServer do
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

  def move_all_games_down(game_server) do
    GenServer.cast(game_server, :move_all_boards_down)
  end

  def join_game(game_server, user_id) do
    GenServer.call(game_server, {:join_game, user_id})
  end

  def leave_game(game_server, user_id) do
    GenServer.call(game_server, {:leave_game, user_id})
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
       game_id: UUID.uuid1(),
       players: [],
       status: :players_joining,
       periodic_mover_pid: periodic_mover_pid
     }, {:continue, :init_periodic}}
  end

  @impl true
  def handle_continue(:init_periodic, %Game{periodic_mover_pid: periodic_mover_pid} = game) do
    this_game_server = self()

    # Set the periodic task to move the piece down
    Tetrex.Periodic.set_work(periodic_mover_pid, fn ->
      move_all_games_down(this_game_server)
    end)

    {:noreply, game, {:continue, :publish_state}}
  end

  @impl true
  def handle_continue(:publish_state, game) do
    publish_update(game)

    {:noreply, game}
  end

  @impl true
  def handle_cast(:move_all_boards_down, %Game{players: players} = game) do
    players
    |> Enum.map(fn {_user_id, %{board_pid: board_pid}} -> BoardServer.try_move_down(board_pid) end)

    {:noreply, game, {:continue, :publish_state}}
  end

  def handle_call(:get_game_id, _from, %Game{game_id: game_id} = game) do
    {:reply, game_id, game}
  end

  def handle_call(:game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call(:game_message, _from, game) do
    {:reply, Game.to_game_message(game), game}
  end

  @impl true
  def handle_call({:join_game, user_id}, _from, %Game{players: players} = game) do
    if player_in_game?(user_id, game) do
      {:reply, {:error, :already_in_game}, game}
    else
      {:ok, board_pid} = BoardServer.start_link()

      player = %{
        user_id: user_id,
        board_pid: board_pid,
        lines_cleared: 0,
        status: :not_ready,
        online: true
      }

      {:reply, :ok, %Game{game | players: [player | players], status: :players_joining},
       {:continue, :publish_state}}
    end
  end

  @impl true
  def handle_call({:leave_game, user_id}, _from, %Game{players: players} = game) do
    player = get_player(user_id, game)

    if is_nil(player) do
      {:reply, {:error, :not_in_game}, game}
    else
      # Process.exit(player.board_pid, :kill)

      {:reply, :ok,
       %Game{
         game
         | players: List.delete(players, player)
       }, {:continue, :publish_state}}
    end
  end

  defp publish_update(%Game{game_id: game_id} = game) do
    Phoenix.PubSub.broadcast!(Tetrex.PubSub, pubsub_topic(game_id), Game.to_game_message(game))
  end

  defp get_player(user_id, %Game{players: players}),
    do: Enum.find(players, nil, &(&1.user_id == user_id))

  defp player_in_game?(user_id, %Game{players: players}),
    do: Enum.any?(players, &(&1.user_id == user_id))
end
