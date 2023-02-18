defmodule TetrexWeb.SinglePlayerGameLive do
  use TetrexWeb, :live_view

  alias Tetrex.GameServer
  alias Tetrex.Game
  alias TetrexWeb.Components.BoardComponents
  alias TetrexWeb.Components.Modal
  alias TetrexWeb.Components.Soundtrack

  @game_over_audio_id "game-over-audio"
  @theme_music_audio_id "theme-music-audio"

  # LiveView Callbacks

  @impl true
  def mount(_params, _session, socket) do
    player_id = 1
    # Should only ever be one game in progress, error if more
    [{game_server, _}] = Registry.lookup(Tetrex.GameRegistry, player_id)

    %Game{
      periodic_mover_pid: periodic_mover
    } = GameServer.game(game_server)

    this_liveview = self()

    # Set the periodic task to move the piece down
    Tetrex.Periodic.set_work(periodic_mover, fn ->
      Process.send(this_liveview, :try_move_down, [])
    end)

    socket =
      socket
      |> assign(game_server: game_server)
      |> assign(game_over_audio_id: @game_over_audio_id)
      |> assign(theme_music_audio_id: @theme_music_audio_id)
      |> pause_game()
      |> game_assigns()

    {:ok, socket}
  end

  @impl true
  def handle_event("start_game", _value, socket),
    do:
      socket
      |> start_game()
      |> noreply_update_game_assigns()

  @impl true
  def handle_event("keypress", %{"key" => "Enter"}, %{assigns: %{status: :game_over}} = socket),
    do:
      socket
      |> new_game()
      |> start_game()
      |> noreply_update_game_assigns()

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
      |> noreply_update_game_assigns()

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
      |> noreply_update_game_assigns()

  @impl true
  def handle_event("keypress", %{"key" => "ArrowDown"}, socket),
    do:
      socket
      |> try_move_down()
      |> noreply_update_game_assigns()

  @impl true
  def handle_event("keypress", %{"key" => "ArrowLeft"}, socket) do
    GameServer.try_move_left(socket.assigns.game_server)

    socket |> noreply_update_game_assigns()
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowRight"}, socket) do
    GameServer.try_move_right(socket.assigns.game_server)

    socket
    |> noreply_update_game_assigns()
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowUp"}, socket) do
    GameServer.rotate(socket.assigns.game_server)

    socket
    |> noreply_update_game_assigns()
  end

  @impl true
  def handle_event("keypress", %{"key" => " "}, socket) do
    GameServer.drop(socket.assigns.game_server)

    socket
    |> noreply_update_game_assigns()
  end

  @impl true
  def handle_event("keypress", %{"key" => "h"}, socket) do
    GameServer.hold(socket.assigns.game_server)

    socket
    |> noreply_update_game_assigns()
  end

  @impl true
  def handle_event("keypress", %{"key" => key}, socket) do
    IO.puts("Unhandled key press: #{key}")

    socket
    |> noreply()
  end

  @impl true
  def handle_info(:try_move_down, socket),
    do:
      socket
      |> try_move_down()
      |> noreply_update_game_assigns()

  # Helper Functions

  defp noreply_update_game_assigns(socket) do
    {:noreply, game_assigns(socket)}
  end

  defp noreply(socket) do
    {:noreply, socket}
  end

  defp try_move_down(socket) do
    GameServer.try_move_down(socket.assigns.game_server)

    socket
    |> game_assigns()
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
    |> game_assigns()
  end

  defp start_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.start_game(game_server)

    socket
    |> play_theme_audio()
    |> game_assigns()
  end

  defp pause_game(%{assigns: %{game_server: game_server}} = socket) do
    GameServer.pause_game(game_server)

    socket
    |> pause_theme_audio()
    |> game_assigns()
  end

  defp game_assigns(socket) do
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

  defp status_change_assigns(%{assigns: %{status: old_status}} = socket, :game_over)
       when old_status != :game_over,
       do:
         socket
         |> play_game_over_audio()

  defp status_change_assigns(socket, _new_status), do: socket
end
