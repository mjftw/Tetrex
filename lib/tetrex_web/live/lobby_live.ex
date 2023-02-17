defmodule TetrexWeb.LobbyLive do
  alias Tetrex.BoardServer
  alias Tetrex.BoardRegistry
  use TetrexWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # TODO: Should be stored in browser session storage, or actually have a users database & login flow
    user_id = 1

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(:user_has_board, BoardRegistry.user_has_board?(user_id))}
  end

  @impl true
  def handle_event("new-single-player-game", _value, socket) do
    user_id = socket.assigns.user_id

    if !BoardRegistry.user_has_board?(user_id) do
      # TODO: Start under a dynamic supervisor rather than unlinked
      BoardServer.start(name: {:via, Registry, {Tetrex.BoardRegistry, user_id}})

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

    if BoardRegistry.user_has_board?(user_id) do
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
