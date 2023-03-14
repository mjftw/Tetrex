defmodule TetrexWeb.MultiplayerGameLive do
  alias Tetrex.GameDynamicSupervisor
  use TetrexWeb, :live_view

  @impl true
  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    {:ok, assign(socket, user_id: user_id)}
  end

  @impl true
  def handle_params(%{"game_id" => game_id}, _uri, socket) do
    {game_server, game} = GameDynamicSupervisor.multiplayer_game_by_id(game_id)
    {:noreply, assign(socket, game: game, game_server: game_server)}
  end
end
