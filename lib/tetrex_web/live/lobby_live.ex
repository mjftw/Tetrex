defmodule TetrexWeb.LobbyLive do
  alias Tetrex.Multiplayer
  alias Tetrex.GameDynamicSupervisor
  use TetrexWeb, :live_view

  @socket_presence_assign_key :users
  @current_user_key :user_id

  use LiveViewUserTracking,
    presence: TetrexWeb.Presence,
    topic: "room:lobby",
    socket_current_user_assign_key: @current_user_key,
    socket_users_assign_key: @socket_presence_assign_key

  @impl true
  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    if connected?(socket) do
      GameDynamicSupervisor.subscribe_multiplayer_game_updates()
    end

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(
       :user_has_single_player_game,
       GameDynamicSupervisor.user_has_single_player_game?(user_id)
     )
     |> assign(:users, %{})
     |> assign(
       :multiplayer_games,
       GameDynamicSupervisor.multiplayer_games() |> Enum.map(fn {_pid, game} -> game end)
     )
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
  def handle_event("new-multiplayer-game", _value, %{assigns: %{user_id: user_id}} = socket) do
    case GameDynamicSupervisor.start_multiplayer_game() do
      {:ok, game_server_pid} ->
        game_id = Multiplayer.GameServer.get_game_id(game_server_pid)
        :ok = Multiplayer.GameServer.join_game(game_server_pid, user_id)

        {:noreply,
         socket
         |> push_redirect(to: Routes.live_path(socket, TetrexWeb.MultiplayerGameLive, game_id))}

      {:error, _error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create multiplayer game")}
    end
  end

  # PubSub handlers
  @impl true
  def handle_info({:created_multiplayer_game, game}, socket) do
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
end
