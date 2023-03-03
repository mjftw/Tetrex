defmodule TetrexWeb.LobbyLive do
  alias TetrexWeb.Presence
  alias Tetrex.GameRegistry
  use TetrexWeb, :live_view

  @room_type "lobby"
  @presence_channel Presence.channel_name(@room_type)

  @impl true
  def mount(_params, %{"user_id" => player_id} = _session, socket) do
    if connected?(socket) do
      Presence.track_room(player_id, @room_type)

      Phoenix.PubSub.subscribe(Tetrex.PubSub, Presence.all_rooms())
    end

    {:ok,
     socket
     |> assign(:player_id, player_id)
     |> assign(:user_has_game, GameRegistry.user_has_game?(player_id))
     |> assign(:users, %{})
     |> presence_assigns()}
  end

  @impl true
  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "presence_diff",
          payload: _joins_leaves
        },
        socket
      ) do
    {:noreply,
     socket
     |> presence_assigns()}
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

  defp presence_assigns(socket) do
    socket
    |> assign(:users, Presence.list(@presence_channel))
  end
end
