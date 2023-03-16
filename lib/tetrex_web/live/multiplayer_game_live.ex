defmodule TetrexWeb.MultiplayerGameLive do
  alias Tetrex.SinglePlayer.GameServer
  alias Tetrex.Multiplayer.GameMessage
  alias Tetrex.Multiplayer.GameServer
  alias Tetrex.GameDynamicSupervisor
  use TetrexWeb, :live_view

  @impl true
  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    {:ok, assign(socket, user_id: user_id)}
  end

  @impl true
  def handle_params(%{"game_id" => game_id}, _uri, socket) do
    case GameDynamicSupervisor.multiplayer_game_by_id(game_id) do
      # TODO: Log an error here
      {:error, _error} ->
        {:noreply, push_redirect(socket, to: Routes.live_path(socket, TetrexWeb.LobbyLive))}

      {:ok, game_server, _game} ->
        if connected?(socket) do
          GameServer.subscribe_updates(game_server)
        end

        initial_game_state = GameServer.get_game_message(game_server)
        {:noreply, assign(socket, game: initial_game_state, game_server: game_server)}
    end
  end

  @impl true
  def handle_info(%GameMessage{} = game_state, socket) do
    {:noreply, assign(socket, game: game_state)}
  end
end
