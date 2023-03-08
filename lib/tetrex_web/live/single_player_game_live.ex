defmodule TetrexWeb.SinglePlayerGameLive do
  use TetrexWeb, :live_view

  alias Tetrex.SinglePlayer.GameMessage
  alias Tetrex.SinglePlayer.GameServer
  alias Tetrex.GameRegistry
  alias Tetrex.SinglePlayer.Game
  alias TetrexWeb.Components.BoardComponents
  alias TetrexWeb.Components.Modal
  alias TetrexWeb.Components.Soundtrack

  @game_over_audio_id "game-over-audio"
  @theme_music_audio_id "theme-music-audio"

  @impl true
  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    games_found = Registry.lookup(GameRegistry, user_id)

    if Enum.count(games_found) == 0 do
      {:ok,
       socket
       |> push_redirect(to: Routes.live_path(socket, TetrexWeb.LobbyLive))}
    else
      # Should only ever be one game in progress, error if more
      [{game_server, _}] = games_found

      if connected?(socket) do
        GameServer.subscribe_updates(game_server)
      end

      socket =
        socket
        |> assign(user_id: user_id)
        |> assign(game_server: game_server)
        |> assign(game_over_audio_id: @game_over_audio_id)
        |> assign(theme_music_audio_id: @theme_music_audio_id)
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
    GameRegistry.remove_game(socket.assigns.user_id)

    socket
    |> push_redirect(to: Routes.live_path(socket, TetrexWeb.LobbyLive))
    |> noreply()
  end

  @impl true
  def handle_event("keypress", %{"key" => "Enter"}, %{assigns: %{status: :game_over}} = socket),
    do:
      socket
      |> new_game()
      |> start_game()
      |> noreply()

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

  defp play_game_over_audio(socket),
    do:
      socket
      |> push_event("stop-audio", %{id: @theme_music_audio_id})
      |> push_event("play-audio", %{id: @game_over_audio_id})

  defp play_theme_audio(socket),
    do:
      socket
      |> push_event("stop-audio", %{id: @game_over_audio_id})
      |> push_event("play-audio", %{id: @theme_music_audio_id})

  defp pause_theme_audio(socket),
    do:
      socket
      |> push_event("pause-audio", %{id: @theme_music_audio_id})

  defp new_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.new_game(game_server)

    socket
  end

  defp start_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.start_game(game_server)

    socket
    |> play_theme_audio()
  end

  defp pause_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.pause_game(game_server)

    socket
    |> pause_theme_audio()
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
         |> play_game_over_audio()

  defp status_change_assigns(socket, _new_status), do: socket
end
