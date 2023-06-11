defmodule TetrexWeb.MultiplayerGameLive do
  alias Tetrex.Multiplayer
  alias Tetrex.SinglePlayer.GameServer
  alias Tetrex.Multiplayer.GameMessage
  alias Tetrex.Multiplayer.GameServer
  alias Tetrex.GameDynamicSupervisor
  alias TetrexWeb.Components.{BoardComponents, Modal}

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
        cond do
          Multiplayer.Game.player_in_game?(game, user_id) ->
            {:noreply,
             socket
             |> put_flash(
               :error,
               "Cannot join as you're already in the game. Is it open in another tab?"
             )
             |> redirect_to_lobby()}

          Multiplayer.Game.has_started?(game) ->
            {:noreply,
             socket
             |> put_flash(
               :error,
               "Cannot join game as it's already started"
             )
             |> redirect_to_lobby()}

          true ->
            if connected?(socket) do
              GameServer.subscribe_updates(game_server_pid)
              GameServer.join_game(game_server_pid, user_id)

              ProcessMonitor.monitor(fn _reason ->
                GameServer.kill_player(game_server_pid, user_id)
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

  @impl true
  def handle_event(
        "keypress",
        %{"key" => "ArrowDown"},
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.try_move_down(game_server_pid, user_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "keypress",
        %{"key" => "ArrowLeft"},
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.try_move_left(game_server_pid, user_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "keypress",
        %{"key" => "ArrowRight"},
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.try_move_right(game_server_pid, user_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "keypress",
        %{"key" => "ArrowUp"},
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.rotate(game_server_pid, user_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "keypress",
        %{"key" => " "},
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.drop(game_server_pid, user_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "keypress",
        %{"key" => "h"},
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.hold(game_server_pid, user_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("keypress", %{"key" => key}, socket) do
    IO.puts("Unhandled key press: #{key}")

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "player-ready",
        %{"user-id" => user_id},
        %{assigns: %{game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.set_player_ready(game_server_pid, user_id, true)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "player-not-ready",
        %{"user-id" => user_id},
        %{assigns: %{game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.set_player_ready(game_server_pid, user_id, false)
    {:noreply, socket}
  end

  def user_player_data!(%GameMessage{players: players}, user_id), do: Map.fetch!(players, user_id)

  def even_users_player_data(players, current_user_id),
    do:
      players
      |> Stream.filter(fn {user_id, _} -> user_id != current_user_id end)
      |> Enum.take_every(2)

  def odd_users_player_data(players, current_user_id),
    do:
      players
      |> Stream.filter(fn {user_id, _} -> user_id != current_user_id end)
      |> Stream.drop(1)
      |> Enum.take_every(2)

  def num_players_in_game(%GameMessage{players: players}), do: Enum.count(players)

  defp redirect_to_lobby(socket),
    do: push_redirect(socket, to: Routes.live_path(socket, TetrexWeb.LobbyLive))
end
