defmodule TetrexWeb.MultiplayerGameLive do
  alias Tetrex.Multiplayer
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
  def handle_params(%{"game_id" => game_id}, _uri, %{assigns: %{user_id: user_id}} = socket) do
    case GameDynamicSupervisor.multiplayer_game_by_id(game_id) do
      # TODO: Log an error here
      {:error, _error} ->
        {:noreply, redirect_to_lobby(socket)}

      {:ok, game_server_pid, game} ->
        if Multiplayer.Game.user_in_game?(game, user_id) do
          {:noreply,
           socket
           |> put_flash(
             :error,
             "Cannot join as you're already in the game. Is it open in another tab?"
           )
           |> redirect_to_lobby()}
        else
          if connected?(socket) do
            GameServer.subscribe_updates(game_server_pid)
            GameServer.join_game(game_server_pid, user_id)

            ProcessMonitor.monitor(fn _reason ->
              GameServer.leave_game(game_server_pid, user_id)
            end)
          end

          initial_game_state = GameServer.get_game_message(game_server_pid)
          {:noreply, assign(socket, game: initial_game_state, game_server_pid: game_server_pid)}
        end
    end
  end

  @impl true
  def handle_info(%GameMessage{} = game_state, socket) do
    {:noreply, assign(socket, game: game_state)}
  end

  defp redirect_to_lobby(socket),
    do: push_redirect(socket, to: Routes.live_path(socket, TetrexWeb.LobbyLive))
end
