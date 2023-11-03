defmodule CarsCommercePuzzleAdventureWeb.LobbyLive do
  alias CarsCommercePuzzleAdventure.Users.UserStore
  alias CarsCommercePuzzleAdventure.Users.User
  alias CarsCommercePuzzleAdventure.Multiplayer
  alias CarsCommercePuzzleAdventure.GameDynamicSupervisor

  use CarsCommercePuzzleAdventureWeb, :live_view

  require Logger

  use LiveViewUserTracking,
    presence: CarsCommercePuzzleAdventureWeb.Presence,
    topic: "room:lobby",
    socket_current_user_assign_key: :current_user,
    socket_users_assign_key: :users

  @impl true
  def mount(_params, %{"user_id" => current_user_id} = _session, socket) do
    {multiplayer_game_pids, multiplayer_games} =
      Enum.unzip(GameDynamicSupervisor.multiplayer_games())

    if connected?(socket) do
      GameDynamicSupervisor.subscribe_multiplayer_game_updates()

      Enum.each(multiplayer_game_pids, &Multiplayer.GameServer.subscribe_updates(&1))
    end

    current_user = UserStore.get_user!(current_user_id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(
       :user_has_single_player_game,
       GameDynamicSupervisor.user_has_single_player_game?(current_user.id)
     )
     |> assign(:users, %{})
     |> assign(:multiplayer_games, multiplayer_games)
     |> mount_presence_init()}
  end

  @impl true
  def handle_event("new-single-player-game", _value, socket) do
    user_id = socket.assigns.current_user.id

    if !GameDynamicSupervisor.user_has_single_player_game?(user_id) do
      GameDynamicSupervisor.start_single_player_game(user_id)

      {:noreply,
       socket
       |> push_redirect(to: ~p"/single-player-game")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Single player game already in progress")}
    end
  end

  @impl true
  def handle_event("resume-single-player-game", _value, socket) do
    user_id = socket.assigns.current_user.id

    if GameDynamicSupervisor.user_has_single_player_game?(user_id) do
      {:noreply,
       socket
       |> push_redirect(to: ~p"/single-player-game")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Cannot find single player game #{1}")}
    end
  end

  @impl true
  def handle_event("new-multiplayer-game", _value, socket) do
    case GameDynamicSupervisor.start_multiplayer_game() do
      {:ok, game_server_pid} ->
        game_id = Multiplayer.GameServer.get_game_id(game_server_pid)

        {:noreply,
         socket
         |> push_redirect(to: ~p"/multiplayer-game/#{game_id}")}

      {:error, error} ->
        Logger.error("Failed to create multiplayer game: #{inspect(error)}")

        {:noreply,
         socket
         |> put_flash(:error, "Failed to create multiplayer game")}
    end
  end

  @impl true
  def handle_event("join-multiplayer-game", %{"game-id" => game_id}, socket) do
    {:noreply,
     socket
     |> push_redirect(to: ~p"/multiplayer-game/#{game_id}")}
  end

  # PubSub handlers
  @impl true
  def handle_info({:created_multiplayer_game, game_server_pid}, socket) do
    Multiplayer.GameServer.subscribe_updates(game_server_pid)
    game = Multiplayer.GameServer.game(game_server_pid)

    {
      :noreply,
      assign(socket, :multiplayer_games, [game | socket.assigns.multiplayer_games])
    }
  end

  @impl true
  def handle_info({:removed_multiplayer_game, game_id}, socket),
    do: {:noreply, socket |> forget_multiplayer_game(game_id)}

  @impl true
  def handle_info(%Multiplayer.GameMessage{game_id: game_id, status: :exiting}, socket),
    do: {:noreply, socket |> forget_multiplayer_game(game_id)}

  @impl true
  def handle_info(%Multiplayer.GameMessage{game_id: game_id}, socket) do
    games = socket.assigns.multiplayer_games

    {:ok, _game_server_pid, game} = GameDynamicSupervisor.multiplayer_game_by_id(game_id)

    case Enum.find_index(games, &(&1.game_id == game_id)) do
      nil ->
        # TODO: Maybe log something here?

        # Didn't know about game, add to list
        {:noreply, assign(socket, multiplayer_games: [game | games])}

      game_index ->
        updated_games = List.replace_at(games, game_index, game)

        {:noreply, assign(socket, multiplayer_games: updated_games)}
    end
  end

  def joinable_multiplayer_games(multiplayer_games),
    do: Enum.filter(multiplayer_games, &(!Multiplayer.Game.has_started?(&1)))

  def in_progress_multiplayer_games(multiplayer_games),
    do: Enum.filter(multiplayer_games, &Multiplayer.Game.has_started?(&1))

  defp forget_multiplayer_game(socket, game_id) do
    updated_games = Enum.filter(socket.assigns.multiplayer_games, &(&1.game_id != game_id))

    assign(socket, multiplayer_games: updated_games)
  end
end
