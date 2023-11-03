defmodule CarsCommercePuzzleAdventureWeb.MultiplayerGameLive do
  alias CarsCommercePuzzleAdventure.Multiplayer
  alias CarsCommercePuzzleAdventure.SinglePlayer.GameServer
  alias CarsCommercePuzzleAdventure.Multiplayer.GameMessage
  alias CarsCommercePuzzleAdventure.Multiplayer.GameServer
  alias CarsCommercePuzzleAdventure.GameDynamicSupervisor
  alias CarsCommercePuzzleAdventureWeb.Components.BoardComponents
  alias CarsCommercePuzzleAdventureWeb.Components.Client.Audio
  alias CarsCommercePuzzleAdventureWeb.Components.Controls
  alias Phoenix.LiveView.JS
  alias Patchwork.Patch

  require Logger

  use CarsCommercePuzzleAdventureWeb, :live_view

  @num_opponent_boards_to_show Application.compile_env(
                                 :cars_commerce_puzzle_adventure,
                                 [
                                   :settings,
                                   :multiplayer,
                                   :num_opponent_boards_to_show
                                 ]
                               )

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

          Multiplayer.Game.is_full?(game) ->
            {:noreply,
             socket
             |> put_flash(
               :error,
               "Cannot join game as it's full"
             )
             |> redirect_to_lobby()}

          true ->
            if connected?(socket) do
              GameServer.subscribe_updates(game_server_pid)
              GameServer.join_game(game_server_pid, user_id)

              ProcessMonitor.monitor(fn _reason ->
                case GameServer.leave_game(game_server_pid, user_id) do
                  :ok ->
                    nil

                  {:error, :cannot_leave_game_in_progress} ->
                    :ok = GameServer.kill_player(game_server_pid, user_id)

                  {:error, error} ->
                    Logger.error(inspect(error))
                end
              end)
            end

            initial_game_state = GameServer.get_game_message(game_server_pid)
            {:noreply, assign(socket, game: initial_game_state, game_server_pid: game_server_pid)}
        end
    end
  end

  @impl true
  def handle_info(%GameMessage{status: :exiting}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "The game has ended")
     |> redirect_to_lobby()}
  end

  @impl true
  def handle_info(%GameMessage{} = game_state, socket) do
    {:noreply,
     socket
     |> handle_status_changes(game_state)
     |> assign(game: game_state)}
  end

  @impl true
  def handle_event(
        "keypress",
        _,
        %{assigns: %{game: %{status: status}}} = socket
      )
      when status in [:players_joining, :finished] do
    {:noreply, socket}
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
        %{"key" => "Shift"},
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.hold(game_server_pid, user_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "keypress",
        %{"key" => ""},
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
        "exit-game",
        _value,
        socket
      ),
      do: {:noreply, socket |> redirect_to_lobby}

  @impl true
  def handle_event(
        "player-not-ready",
        %{"user-id" => user_id},
        %{assigns: %{game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.set_player_ready(game_server_pid, user_id, false)
    {:noreply, socket}
  end

  def handle_event(
        "hold",
        _value,
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.hold(game_server_pid, user_id)
    {:noreply, socket}
  end

  def handle_event(
        "rotate",
        _value,
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.rotate(game_server_pid, user_id)
    {:noreply, socket}
  end

  def handle_event(
        "left",
        _value,
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.try_move_left(game_server_pid, user_id)
    {:noreply, socket}
  end

  def handle_event(
        "right",
        _value,
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.try_move_right(game_server_pid, user_id)
    {:noreply, socket}
  end

  def handle_event(
        "down",
        _value,
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.try_move_down(game_server_pid, user_id)
    {:noreply, socket}
  end

  def handle_event(
        "drop",
        _value,
        %{assigns: %{user_id: user_id, game_server_pid: game_server_pid}} = socket
      ) do
    GameServer.drop(game_server_pid, user_id)
    {:noreply, socket}
  end

  def user_player_data!(%GameMessage{players: players}, user_id) do
    {_id, data} = Enum.find(players, fn {id, _} -> id == user_id end)
    data
  end

  defp opponent_data_to_display(players, current_user_id) do
    players
    |> Stream.filter(fn {user_id, _} -> user_id != current_user_id end)
    |> Stream.take(@num_opponent_boards_to_show)
  end

  def even_opponents_player_data(players, current_user_id),
    do:
      players
      |> opponent_data_to_display(current_user_id)
      |> Enum.take_every(2)

  def odd_opponents_player_data(players, current_user_id),
    do:
      players
      |> opponent_data_to_display(current_user_id)
      |> Stream.drop(1)
      |> Enum.take_every(2)

  def num_players_in_game(%GameMessage{players: players}), do: Enum.count(players)

  def num_alive_opponents(%GameMessage{players: players}) do
    num_alive_players =
      players
      |> Stream.filter(fn {_user_id, %{status: status}} -> status != :dead end)
      |> Enum.count()
  end

  defp handle_status_changes(
         %{assigns: %{game: old_game, user_id: user_id}} = socket,
         %GameMessage{} = new_game
       ) do
    old_player_status = user_player_data!(old_game, user_id).status
    new_player_status = user_player_data!(new_game, user_id).status

    old_game_status = old_game.status
    new_game_status = new_game.status

    case {old_player_status, old_game_status, new_player_status, new_game_status} do
      {_, :players_joining, _, :playing} ->
        socket |> Audio.play_theme_audio()

      {:ready, :playing, :dead, _} ->
        socket |> Audio.play_game_over_audio()

      {_, :playing, :ready, :finished} ->
        socket |> Audio.pause_theme_audio()

      _ ->
        socket
    end
  end

  defp redirect_to_lobby(socket),
    do: push_redirect(socket, to: ~p"/")
end
