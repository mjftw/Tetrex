defmodule TetrexWeb.LobbyLive do
  alias Tetrex.Users.UserStore
  alias Tetrex.Users.User
  alias Tetrex.Users.NameGenerator
  alias Tetrex.Multiplayer
  alias Tetrex.GameDynamicSupervisor
  alias TetrexWeb.Components.BoardComponents

  use TetrexWeb, :live_view

  require Logger

  use LiveViewUserTracking,
    presence: TetrexWeb.Presence,
    topic: "users:global",
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

    current_user =
      case UserStore.get_user(current_user_id) do
        nil ->
          # Generate a random username if user doesn't exist
          username = NameGenerator.generate()
          UserStore.put_user(current_user_id, username)
          UserStore.get_user!(current_user_id)

        user ->
          user
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(
       :user_has_single_player_game,
       GameDynamicSupervisor.user_has_single_player_game?(current_user.id)
     )
     |> assign(
       :single_player_game_preview,
       get_single_player_game_preview(current_user.id)
     )
     |> assign(:users, %{})
     |> assign(:multiplayer_games, multiplayer_games)
     |> assign(:editing_username, false)
     |> assign(:temp_username, "")
     |> mount_presence_init_with_status(:in_lobby)}
  end

  @impl true
  def handle_event("new-single-player-game", _value, socket) do
    user_id = socket.assigns.current_user.id

    if !GameDynamicSupervisor.user_has_single_player_game?(user_id) do
      case GameDynamicSupervisor.start_single_player_game(user_id) do
        {:ok, _game_server_pid} ->
          {:noreply,
           socket
           |> assign(:user_has_single_player_game, true)
           |> assign(:single_player_game_preview, get_single_player_game_preview(user_id))
           |> push_redirect(to: ~p"/single-player-game")}

        {:error, _error} ->
          {:noreply, put_flash(socket, :error, "Failed to start single player game")}
      end
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
      # Game no longer exists, update the preview state
      {:noreply,
       socket
       |> assign(:user_has_single_player_game, false)
       |> assign(:single_player_game_preview, nil)
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

  @impl true
  def handle_event("edit-username", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_username, true)
     |> assign(:temp_username, socket.assigns.current_user.username)}
  end

  @impl true
  def handle_event("cancel-edit-username", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_username, false)
     |> assign(:temp_username, "")}
  end

  @impl true
  def handle_event("update-username", params, socket) do
    username =
      case params do
        # From button click
        %{"username" => username} -> username
        # From keyboard event
        %{"value" => username} -> username
        # Fallback to current temp
        _ -> socket.assigns.temp_username
      end

    trimmed_username = String.trim(username)

    if valid_username?(trimmed_username) do
      UserStore.put_user(socket.assigns.current_user.id, trimmed_username)
      updated_user = %{socket.assigns.current_user | username: trimmed_username}

      # Update presence with new username
      update_presence_username(socket, updated_user)

      {:noreply,
       socket
       |> assign(:current_user, updated_user)
       |> assign(:editing_username, false)
       |> assign(:temp_username, "")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please enter a valid username")}
    end
  end

  @impl true
  def handle_event("temp-username-change", %{"value" => username}, socket) do
    {:noreply,
     socket
     |> assign(:temp_username, username)}
  end

  @impl true
  def handle_event("handle-keyboard", %{"key" => "Enter", "value" => username}, socket) do
    handle_event("update-username", %{"value" => username}, socket)
  end

  @impl true
  def handle_event("handle-keyboard", %{"key" => "Escape"}, socket) do
    handle_event("cancel-edit-username", %{}, socket)
  end

  @impl true
  def handle_event("handle-keyboard", _params, socket) do
    # Ignore other keys
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
    do:
      Enum.filter(
        multiplayer_games,
        &(!Multiplayer.Game.has_started?(&1) && Multiplayer.Game.num_alive_players(&1) > 0)
      )

  def in_progress_multiplayer_games(multiplayer_games),
    do:
      Enum.filter(
        multiplayer_games,
        &(&1.status == :playing && Multiplayer.Game.num_alive_players(&1) > 0)
      )

  defp get_single_player_game_preview(user_id) do
    case GameDynamicSupervisor.user_single_player_game(user_id) do
      nil ->
        nil

      {_pid,
       %Tetrex.SinglePlayer.Game{
         board_pid: board_pid,
         status: status,
         lines_cleared: lines_cleared
       }} ->
        try do
          board_data = Tetrex.BoardServer.preview(board_pid)
          %{board: board_data, status: status, lines_cleared: lines_cleared}
        rescue
          _ -> nil
        end
    end
  end

  defp forget_multiplayer_game(socket, game_id) do
    updated_games = Enum.filter(socket.assigns.multiplayer_games, &(&1.game_id != game_id))

    assign(socket, multiplayer_games: updated_games)
  end

  defp valid_username?(username) do
    String.length(username) > 0 && String.length(username) <= 50
  end

  defp update_presence_username(socket, updated_user) do
    if connected?(socket) do
      # Update presence in global user topic
      TetrexWeb.Presence.update(
        self(),
        "users:global",
        updated_user.id,
        %{
          user: updated_user,
          joined_at: inspect(System.system_time(:second)),
          status: :in_lobby
        }
      )
    end
  end

  defp mount_presence_init_with_status(socket, status) do
    if connected?(socket) do
      %User{id: current_user_id} = user = socket.assigns.current_user

      {:ok, _} =
        TetrexWeb.Presence.track(
          self(),
          "users:global",
          current_user_id,
          %{
            user: user,
            joined_at: inspect(System.system_time(:second)),
            status: status
          }
        )

      Phoenix.PubSub.subscribe(Tetrex.PubSub, "users:global")
    end

    handle_presence_joins(socket, TetrexWeb.Presence.list("users:global"))
  end
end
