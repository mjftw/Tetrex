defmodule TetrexWeb.LobbyLive do
  alias Tetrex.GameRegistry
  use TetrexWeb, :live_view

  @impl true
  def mount(_params, %{"user_id" => player_id} = _session, socket) do
    {:ok,
     socket
     |> assign(:player_id, player_id)
     |> assign(:user_has_game, GameRegistry.user_has_game?(player_id))}
  end

  @impl true
  def handle_event("new-single-player-game", _value, socket) do
    player_id = socket.assigns.player_id

    if !GameRegistry.user_has_game?(player_id) do
      Tetrex.GameRegistry.start_new_game(player_id)

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
    player_id = socket.assigns.player_id

    if GameRegistry.user_has_game?(player_id) do
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
