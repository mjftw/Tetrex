defmodule TetrexWeb.AdminLive do
  alias Tetrex.Users.User
  alias ElixirSense.Log
  alias Tetrex.GameDynamicSupervisor
  alias Tetrex.Users.UserStore
  alias Tetrex.Multiplayer

  use TetrexWeb, :live_view

  require Logger

  use LiveViewUserTracking,
    presence: TetrexWeb.Presence,
    topic: "room:lobby",
    socket_current_user_assign_key: :current_user,
    socket_users_assign_key: :users

  @admin_panel_username Application.compile_env!(:tetrex, [:admin, :admin_panel_username])
  @admin_panel_password Application.compile_env!(:tetrex, [:admin, :admin_panel_password])

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
     |> assign(:multiplayer_games, multiplayer_games)
     |> assign(:users, %{})
     |> mount_presence_init()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # If credentials don't match, redirect away
    with %{assigns: %{current_user: %User{username: @admin_panel_username}}} <- socket,
         %{"pwd" => @admin_panel_password} <- params do
      {:noreply, socket}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "This is not the page you are looking for")
         |> push_redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("force-start", %{"game-id" => game_id}, socket) do
    {:ok, game_server, game} = GameDynamicSupervisor.multiplayer_game_by_id(game_id)

    Multiplayer.GameServer.force_start(game_server)
    {:noreply, socket}
  end

  @impl true
  def handle_event("increase-level", %{"game-id" => game_id}, socket) do
    {:ok, game_server, game} = GameDynamicSupervisor.multiplayer_game_by_id(game_id)

    Multiplayer.GameServer.increase_game_level(game_server, game.level + 1)
    {:noreply, socket}
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
    updated_games = Enum.filter(socket.assigns.multiplayer_games, &(&1.game_id != game_id))

    {:noreply, assign(socket, multiplayer_games: updated_games)}
  end

  @impl true
  def handle_info(%Multiplayer.GameMessage{game_id: game_id}, socket) do
    games = socket.assigns.multiplayer_games

    {:ok, _game_server_pid, game} = GameDynamicSupervisor.multiplayer_game_by_id(game_id)

    case Enum.find_index(games, &(&1.game_id == game_id)) do
      nil ->
        # Didn't know about game, add to list
        {:noreply, assign(socket, multiplayer_games: [game | games])}

      game_index ->
        updated_games = List.replace_at(games, game_index, game)

        {:noreply, assign(socket, multiplayer_games: updated_games)}
    end
  end
end
