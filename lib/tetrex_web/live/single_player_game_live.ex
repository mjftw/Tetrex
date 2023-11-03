defmodule CarsCommercePuzzleAdventureWeb.SinglePlayerGameLive do
  use CarsCommercePuzzleAdventureWeb, :live_view

  alias CarsCommercePuzzleAdventure.GameDynamicSupervisor
  alias CarsCommercePuzzleAdventure.SinglePlayer.GameMessage
  alias CarsCommercePuzzleAdventure.SinglePlayer.GameServer
  alias CarsCommercePuzzleAdventure.SinglePlayer.Game
  alias CarsCommercePuzzleAdventureWeb.Components.BoardComponents
  alias CarsCommercePuzzleAdventureWeb.Components.Client.Audio
  alias CarsCommercePuzzleAdventureWeb.Components.Controls
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    case GameDynamicSupervisor.user_single_player_game(user_id) do
      nil ->
        {:ok, push_redirect(socket, to: ~p"/")}

      {game_server, _game} ->
        if connected?(socket) do
          GameServer.subscribe_updates(game_server)
        end

        socket =
          socket
          |> assign(user_id: user_id)
          |> assign(game_server: game_server)
          |> initial_game_assigns()
          |> pause_game_if_playing()

        {:ok, socket}
    end
  end

  @impl true
  def handle_info(
        %GameMessage{board_preview: preview, status: status, lines_cleared: lines_cleared},
        socket
      ),
      do:
        socket
        |> status_change_assigns(status)
        |> assign(:board, preview)
        |> assign(:lines_cleared, lines_cleared)
        |> assign(:status, status)
        |> noreply()

  @impl true
  def handle_event("start_game", _value, socket),
    do:
      socket
      |> start_game()
      |> noreply()

  @impl true
  def handle_event("quit_game", _value, socket) do
    GameDynamicSupervisor.remove_single_player_game(socket.assigns.user_id)

    socket
    |> push_redirect(to: ~p"/")
    |> noreply()
  end

  @impl true
  def handle_event("new_game", _value, socket),
    do:
      socket
      |> new_game()
      |> noreply()

  def handle_event("hold", _value, socket) do
    GameServer.hold(socket.assigns.game_server)

    socket
    |> noreply()
  end

  def handle_event("rotate", _value, socket) do
    GameServer.rotate(socket.assigns.game_server)

    socket
    |> noreply()
  end

  def handle_event("left", _value, socket) do
    GameServer.try_move_left(socket.assigns.game_server)

    socket
    |> noreply()
  end

  def handle_event("right", _value, socket) do
    GameServer.try_move_right(socket.assigns.game_server)

    socket
    |> noreply()
  end

  def handle_event("down", _value, socket) do
    GameServer.try_move_down(socket.assigns.game_server)

    socket
    |> noreply()
  end

  def handle_event("drop", _value, socket) do
    GameServer.drop(socket.assigns.game_server)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("keypress", _, %{assigns: %{status: :game_over}} = socket),
    do:
      socket
      |> noreply()

  @impl true
  def handle_event("keypress", %{"key" => "Escape"}, %{assigns: %{status: :paused}} = socket),
    do:
      socket
      |> start_game()
      |> noreply()

  @impl true
  def handle_event("keypress", _, %{assigns: %{status: :paused}} = socket),
    do:
      socket
      |> noreply()

  @impl true
  def handle_event("keypress", %{"key" => "Escape"}, %{assigns: %{status: :playing}} = socket),
    do:
      socket
      |> pause_game()
      |> noreply()

  @impl true
  def handle_event("keypress", %{"key" => "ArrowDown"}, socket) do
    GameServer.try_move_down(socket.assigns.game_server)
    socket |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowLeft"}, socket) do
    GameServer.try_move_left(socket.assigns.game_server)

    socket |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowRight"}, socket) do
    GameServer.try_move_right(socket.assigns.game_server)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowUp"}, socket) do
    GameServer.rotate(socket.assigns.game_server)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => " "}, socket) do
    GameServer.drop(socket.assigns.game_server)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => "h"}, socket) do
    GameServer.hold(socket.assigns.game_server)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => "Shift"}, socket) do
    GameServer.hold(socket.assigns.game_server)

    socket
    |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => key}, socket) do
    IO.puts("Unhandled key press: #{key}")

    socket
    |> noreply()
  end

  # Helper Functions

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp initial_game_assigns(socket) do
    %Game{
      lines_cleared: lines_cleared,
      status: status
    } = GameServer.game(socket.assigns.game_server)

    preview = GameServer.board_preview(socket.assigns.game_server)

    socket
    |> status_change_assigns(status)
    |> assign(:board, preview)
    |> assign(:lines_cleared, lines_cleared)
    |> assign(:status, status)
  end

  defp new_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.new_game(game_server, true)

    socket
    |> Audio.play_theme_audio()
  end

  defp start_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.start_game(game_server)

    socket
    |> Audio.play_theme_audio()
  end

  defp pause_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.pause_game(game_server)

    socket
    |> Audio.pause_theme_audio()
  end

  defp pause_game_if_playing(%{assigns: %{status: :playing}} = socket),
    do:
      socket
      |> pause_game()

  defp pause_game_if_playing(%{assigns: %{status: _}} = socket), do: socket

  defp status_change_assigns(%{assigns: %{status: old_status}} = socket, :game_over)
       when old_status != :game_over,
       do:
         socket
         |> Audio.play_game_over_audio()

  defp status_change_assigns(socket, _new_status), do: socket
end
