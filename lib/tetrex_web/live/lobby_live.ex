defmodule TetrexWeb.LobbyLive do
  alias Tetrex.GameRegistry
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
    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(:user_has_game, GameRegistry.user_has_game?(user_id))
     |> assign(:users, %{})
     |> mount_presence_init()}
  end

  @impl true
  def handle_event("new-single-player-game", _value, socket) do
    user_id = socket.assigns.user_id

    if !GameRegistry.user_has_game?(user_id) do
      Tetrex.GameRegistry.start_new_game(user_id)

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

    if GameRegistry.user_has_game?(user_id) do
      {:noreply,
       socket
       |> push_redirect(to: Routes.live_path(socket, TetrexWeb.SinglePlayerGameLive))}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Cannot find single player game")}
    end
  end
end
