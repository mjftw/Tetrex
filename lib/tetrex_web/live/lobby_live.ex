defmodule TetrexWeb.LobbyLive do
  alias Tetrex.Multiplayer
  alias Tetrex.GameDynamicSupervisor
  use TetrexWeb, :live_view

  require Logger

  @socket_presence_assign_key :users
  @current_user_key :user_id

  use LiveViewUserTracking,
    presence: TetrexWeb.Presence,
    topic: "room:lobby",
    socket_current_user_assign_key: @current_user_key,
    socket_users_assign_key: @socket_presence_assign_key

  @impl true
  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    {multiplayer_game_pids, multiplayer_games} =
      Enum.unzip(GameDynamicSupervisor.multiplayer_games())

    if connected?(socket) do
      GameDynamicSupervisor.subscribe_multiplayer_game_updates()

      Enum.each(multiplayer_game_pids, &Multiplayer.GameServer.subscribe_updates(&1))
    end

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(
       :user_has_single_player_game,
       GameDynamicSupervisor.user_has_single_player_game?(user_id)
     )
     |> assign(:users, %{})
     |> assign(:multiplayer_games, multiplayer_games)
     |> mount_presence_init()}
  end

  @impl true
  def handle_event("new-single-player-game", _value, socket) do
    user_id = socket.assigns.user_id

    if !GameDynamicSupervisor.user_has_single_player_game?(user_id) do
      GameDynamicSupervisor.start_single_player_game(user_id)

      {:noreply,
       socket
       |> push_redirect(to: Routes.live_path(socket, TetrexWeb.SinglePlayerGameLive))}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Single player game already in progress")}
    end
  end

  @impl true
  def handle_event("resume-single-player-game", _value, socket) do
    user_id = socket.assigns.user_id

    if GameDynamicSupervisor.user_has_single_player_game?(user_id) do
      {:noreply,
       socket
       |> push_redirect(to: Routes.live_path(socket, TetrexWeb.SinglePlayerGameLive))}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Cannot find single player game")}
    end
  end

  @impl true
  def handle_event("new-multiplayer-game", _value, socket) do
    case GameDynamicSupervisor.start_multiplayer_game() do
      {:ok, game_server_pid} ->
        game_id = Multiplayer.GameServer.get_game_id(game_server_pid)

        {:noreply,
         socket
         |> push_redirect(to: Routes.live_path(socket, TetrexWeb.MultiplayerGameLive, game_id))}

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
     |> push_redirect(to: Routes.live_path(socket, TetrexWeb.MultiplayerGameLive, game_id))}
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
  def handle_info({:removed_multiplayer_game, game_id}, socket) do
    {
      :noreply,
      assign(
        socket,
        :multiplayer_games,
        Enum.filter(socket.assigns.multiplayer_games, &(&1.game_id != game_id))
      )
    }
  end

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
end
