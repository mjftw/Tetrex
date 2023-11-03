defmodule CarsCommercePuzzleAdventure.GameDynamicSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor
  alias Phoenix.PubSub
  alias CarsCommercePuzzleAdventure.SinglePlayer
  alias CarsCommercePuzzleAdventure.Multiplayer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def multiplayer_pubsub_topic, do: "GameDynamicSupervisor:multiplayer-game"

  def subscribe_multiplayer_game_updates() do
    Phoenix.PubSub.subscribe(
      CarsCommercePuzzleAdventure.PubSub,
      multiplayer_pubsub_topic()
    )
  end

  # TODO prevent creating a new game for a user that has one already
  def start_single_player_game(user_id) do
    case DynamicSupervisor.start_child(__MODULE__, %{
           id: :ignored,
           start: {SinglePlayer.GameServer, :start_link, [[user_id: user_id]]}
         }) do
      :ignore -> {:error, "SinglePlayer.GameServer ignored start request"}
      {:error, error} -> {:error, error}
      {:ok, child_pid} -> {:ok, child_pid}
    end
  end

  def remove_single_player_game(user_id) do
    case user_single_player_game(user_id) do
      nil -> {:error, :game_not_found}
      {game_pid, _} -> DynamicSupervisor.terminate_child(__MODULE__, game_pid)
    end
  end

  def single_player_games() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Stream.filter(
      &match?({_, _pid, :worker, [CarsCommercePuzzleAdventure.SinglePlayer.GameServer]}, &1)
    )
    |> Stream.map(fn {_, pid, _, _} -> pid end)
    |> Stream.map(&Task.async(fn -> {&1, SinglePlayer.GameServer.game(&1)} end))
    |> Enum.map(&Task.await/1)
  end

  def user_single_player_game(user_id) do
    user_games =
      single_player_games()
      |> Enum.filter(fn {_pid, %SinglePlayer.Game{user_id: game_user_id}} ->
        game_user_id == user_id
      end)

    case user_games do
      [] -> nil
      [{pid, game}] -> {pid, game}
    end
  end

  def user_has_single_player_game?(user_id) do
    case user_single_player_game(user_id) do
      nil -> false
      _game -> true
    end
  end

  def start_multiplayer_game() do
    case DynamicSupervisor.start_child(__MODULE__, %{
           id: :ignored,
           start: {Multiplayer.GameServer, :start_link, [[]]}
         }) do
      :ignore ->
        {:error, "Multiplayer.GameServer ignored start request"}

      {:error, error} ->
        {:error, error}

      {:ok, child_pid} ->
        publish_create_multiplayer_game(child_pid)
        {:ok, child_pid}
    end
  end

  def multiplayer_games() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Stream.filter(&match?({_, _pid, :worker, [CarsCommercePuzzleAdventure.Multiplayer.GameServer]}, &1))
    |> Stream.map(fn {_, pid, _, _} -> pid end)
    |> Stream.map(&Task.async(fn -> {&1, Multiplayer.GameServer.game(&1)} end))
    |> Enum.map(&Task.await/1)
  end

  def multiplayer_game_by_id(game_id) do
    case Enum.find(multiplayer_games(), nil, fn {_pid, game} -> game.game_id == game_id end) do
      nil -> {:error, :game_not_found}
      {game_pid, game} -> {:ok, game_pid, game}
    end
  end

  def remove_multiplayer_game(game_id) do
    with {:ok, game_pid, _game} <- multiplayer_game_by_id(game_id),
         :ok <- DynamicSupervisor.terminate_child(__MODULE__, game_pid) do
      publish_remove_multiplayer_game(game_id)
      :ok
    else
      {:error, error} ->
        {:error, error}
    end
  end

  def remove_multiplayer_game_by_pid(game_pid, game_id) do
    DynamicSupervisor.terminate_child(__MODULE__, game_pid)
    publish_remove_multiplayer_game(game_id)
  end

  defp publish_create_multiplayer_game(multiplayer_game_pid),
    do:
      PubSub.broadcast!(
        CarsCommercePuzzleAdventure.PubSub,
        multiplayer_pubsub_topic(),
        {:created_multiplayer_game, multiplayer_game_pid}
      )

  defp publish_remove_multiplayer_game(game_id),
    do:
      PubSub.broadcast!(
        CarsCommercePuzzleAdventure.PubSub,
        multiplayer_pubsub_topic(),
        {:removed_multiplayer_game, game_id}
      )

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
