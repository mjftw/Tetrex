defmodule TetrexWeb.SinglePlayerGameLive do
  use TetrexWeb, :live_view

  alias Tetrex.Periodic
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
    user_id = 1
    # Should only ever be one game in progress, error if more
    [{board_server, _}] = Registry.lookup(Tetrex.BoardRegistry, user_id)

    this_liveview = self()

    # Create a periodic task to move the piece down
    {:ok, periodic_mover} =
      Tetrex.Periodic.start_link(
        [
          period_ms: 1000,
          start: false,
          work: fn ->
            Process.send(this_liveview, :try_move_down, [])
          end,
          to: board_server
        ],
        []
      )

    socket =
      socket
      |> assign(game_over_audio_id: @game_over_audio_id)
      |> assign(theme_music_audio_id: @theme_music_audio_id)
      |> assign(board_server: board_server)
      |> assign(periodic_mover: periodic_mover)
      |> new_game()

    {:ok, socket}
  end

  @impl true
  def handle_event("start_game", _value, socket), do: {:noreply, start_game(socket)}

  @impl true
  def handle_event("keypress", %{"key" => "Enter"}, %{assigns: %{status: :game_over}} = socket) do
    # TODO: Move to common function
    {:noreply, new_game(socket, true)}
  end

  @impl true
  def handle_event("keypress", _, %{assigns: %{status: :game_over}} = socket),
    do: {:noreply, socket}

  @impl true
  def handle_event("keypress", %{"key" => "ArrowDown"}, socket) do
    # Reset the move timer so we don't get double moves
    Periodic.reset_timer(socket.assigns.periodic_mover)

    {:noreply, try_move_down(socket)}
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
  def handle_event("keypress", %{"key" => " "}, socket) do
    socket =
      case BoardServer.drop(socket.assigns.board_server) do
        # Failed to move piece, which means it hit the bottom or another piece
        {preview, lines_cleared} when preview.active_tile_fits ->
          socket
          |> assign(:board, preview)
          |> update(:lines_cleared, &(&1 + lines_cleared))
          |> update_level()
          |> maybe_remove_blocking(lines_cleared)

        # Game over :-(
        {preview, _} ->
          socket
          |> assign(:board, preview)
          |> game_over()
      end

    {:noreply, socket}
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

  @impl true
  def handle_info(:try_move_down, socket),
    do: {:noreply, try_move_down(socket)}

  @impl true
  def handle_info(:add_blocking_row, socket) do
    socket =
      case BoardServer.add_blocking_row(socket.assigns.board_server) do
        preview when preview.active_tile_fits ->
          socket
          |> assign(:board, preview)

        # Game over :-(
        preview ->
          socket
          |> assign(:board, preview)
          |> game_over()
      end

    {:noreply, socket}
  end

  defp try_move_down(socket) do
    case BoardServer.try_move_down(socket.assigns.board_server) do
      # Moved without collision
      {:moved, preview, _} ->
        socket
        |> assign(:board, preview)

      # Failed to move piece, which means it hit the bottom or another piece
      {_, preview, lines_cleared} when preview.active_tile_fits ->
        socket
        |> assign(:board, preview)
        |> update(:lines_cleared, &(&1 + lines_cleared))
        |> update_level()
        |> maybe_remove_blocking(lines_cleared)

      # Game over :-(
      {_, preview, _} ->
        socket
        |> assign(:board, preview)
        |> game_over()
    end
  end

  defp game_over(socket) do
    # Stop sending periodic moves
    Periodic.stop_timer(socket.assigns.periodic_mover)

    socket
    |> assign(:status, :game_over)
    |> push_event("stop-audio", %{id: @theme_music_audio_id})
    |> push_event("play-audio", %{id: @game_over_audio_id})
  end

  defp start_game(socket) do
    # Start sending periodic moves
    Periodic.start_timer(socket.assigns.periodic_mover)

    socket
    |> assign(status: :playing)
    |> push_event("play-audio", %{id: @theme_music_audio_id})
  end

  defp new_game(socket, is_playing \\ false) do
    preview = BoardServer.preview(socket.assigns.board_server)

    # TODO: This should all be stored in the Game struct, along with the board
    #       and NOT be on the socket props!!!
    socket =
      socket
      |> assign(:board, preview)
      |> assign(lines_cleared: 0)
      |> update_level()
      |> push_event("stop-audio", %{id: @game_over_audio_id})

    socket =
      if is_playing do
        socket |> start_game()
      else
        socket |> assign(:status, :intro)
      end

    socket
  end

  defp maybe_remove_blocking(socket, lines_cleared) do
    if lines_cleared >= 4 do
      BoardServer.remove_blocking_row(socket.assigns.board_server)
    end

    socket
  end

  defp update_level(socket) do
    speed =
      socket.assigns.lines_cleared
      |> level()
      |> level_speed()

    Periodic.set_period(socket.assigns.periodic_mover, floor(speed * 1000))

    socket
  end

  defp level(lines_cleared) do
    div(lines_cleared, 10)
  end

  defp level_speed(level) do
    # For explanation see: https://tetris.fandom.com/wiki/Tetris_(NES,_Nintendo)
    frames_per_gridcell =
      case level do
        0 -> 48
        1 -> 43
        2 -> 38
        3 -> 33
        4 -> 28
        5 -> 23
        6 -> 18
        7 -> 13
        8 -> 8
        9 -> 6
        _ when 10 <= level and level <= 12 -> 5
        _ when 13 <= level and level <= 15 -> 4
        _ when 16 <= level and level <= 18 -> 3
        _ when 19 <= level and level <= 28 -> 2
        _ -> 1
      end

    frames_per_gridcell / 60
  end
end
