defmodule TetrexWeb.SignupLive do
  alias Tetrex.Users.UserStore
  use TetrexWeb, :live_view

  require Logger

  @socket_presence_assign_key :users
  @current_user_key :current_user

  @impl true
  def mount(_params, %{"user_id" => current_user_id} = _session, socket) do
    {:ok, assign(socket, :current_user_id, current_user_id)}
  end

  @impl true
  def handle_event("set-username", %{"signup" => %{"username" => username}}, socket) do
    UserStore.put_user(socket.assigns.current_user_id, username)

    {:noreply,
     socket
     |> push_redirect(to: Routes.live_path(socket, TetrexWeb.LobbyLive))}
  end
end
