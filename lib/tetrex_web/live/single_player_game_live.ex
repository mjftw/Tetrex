defmodule TetrexWeb.SinglePlayerGameLive do
  use TetrexWeb, :live_view

  alias TetrexWeb.Components.BoardComponents
  alias Tetrex.BoardServer
  alias TetrexWeb.Components.Modal
  alias TetrexWeb.Components.Soundtrack

  @board_height 20
  @board_width 10

  @game_over_audio_id "game-over-audio"
  @theme_music_audio_id "theme-music-audio"

  @impl true
  def mount(_params, _session, socket) do
    seed = Enum.random(0..10_000_000)

    # Using name registration for now as only one game
    board_server = Tetrex.BoardServer

    preview = BoardServer.new(board_server, @board_height, @board_width, seed)

    socket =
      socket
      |> assign(game_over_audio_id: @game_over_audio_id)
      |> assign(theme_music_audio_id: @theme_music_audio_id)
      |> assign(board_server: board_server)
      |> assign(board: preview)
      |> assign(score: 0)
      |> assign(status: :intro)

    {:ok, socket}
  end

  @impl true
  def handle_event("start_game", _value, socket) do
    {:noreply,
     socket |> assign(status: :playing) |> push_event("play-audio", %{id: @theme_music_audio_id})}
  end

  @impl true
  def handle_event("keypress", %{"key" => "Enter"}, %{assigns: %{status: :game_over}} = socket) do
    {:noreply, socket |> push_redirect(to: Routes.live_path(socket, __MODULE__))}
  end

  @impl true
  def handle_event("keypress", _, %{assigns: %{status: :game_over}} = socket),
    do: {:noreply, socket}

  @impl true
  def handle_event("keypress", %{"key" => "ArrowDown"}, socket) do
    case BoardServer.try_move_down(socket.assigns.board_server) do
      # Moved without collision
      {:moved, preview, _} ->
        {:noreply,
         socket
         |> assign(:board, preview)}

      # Failed to move piece, which means it hit the bottom or another piece
      {_, preview, lines_cleared} when preview.active_tile_fits ->
        {:noreply,
         socket
         |> assign(:board, preview)
         |> update(:score, &(&1 + lines_cleared))}

      # Game over :-(
      {_, preview, _} ->
        {:noreply,
         socket
         |> assign(:board, preview)
         |> assign(:status, :game_over)
         |> push_event("pause-audio", %{id: @theme_music_audio_id})
         |> push_event("play-audio", %{id: @game_over_audio_id})}
    end
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowLeft"}, socket) do
    case BoardServer.try_move_left(socket.assigns.board_server) do
      {:moved, preview} -> {:noreply, assign(socket, :board, preview)}
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowRight"}, socket) do
    case BoardServer.try_move_right(socket.assigns.board_server) do
      {:moved, preview} -> {:noreply, assign(socket, :board, preview)}
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowUp"}, socket) do
    preview = BoardServer.rotate(socket.assigns.board_server)
    {:noreply, assign(socket, :board, preview)}
  end

  @impl true
  def handle_event("keypress", %{"key" => "h"}, socket) do
    preview = BoardServer.hold(socket.assigns.board_server)
    {:noreply, assign(socket, :board, preview)}
  end

  @impl true
  def handle_event("keypress", %{"key" => key}, socket) do
    IO.puts("Unhandled key press: #{key}")
    {:noreply, socket}
  end
end
