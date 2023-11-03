defmodule CarsCommercePuzzleAdventureWeb.SignupLive do
  alias CarsCommercePuzzleAdventure.Users.UserStore
  use CarsCommercePuzzleAdventureWeb, :live_view

  require Logger

  @socket_presence_assign_key :users
  @current_user_key :current_user

  @impl true
  def mount(_params, %{"user_id" => current_user_id} = _session, socket) do
    {:ok, assign(socket, :current_user_id, current_user_id)}
  end

  @impl true
  def handle_event("set-username", %{"username" => username}, socket) do
    if !valid_username?(username) do
      {:noreply,
       socket
       |> put_flash(:error, "Looks like that name is invalid - maybe try something else?")}
    else
      UserStore.put_user(socket.assigns.current_user_id, username)

      {:noreply,
       socket
       |> push_redirect(to: ~p"/")}
    end
  end

  defp valid_username?(username) do
    String.length(username) > 0
  end
end
