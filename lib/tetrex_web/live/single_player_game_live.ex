defmodule TetrexWeb.SinglePlayerGameLive do
  use TetrexWeb, :live_view

  alias Tetrex.GameServer
  alias Tetrex.Game
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
    player_id = 1
    # Should only ever be one game in progress, error if more
    [{game_server, _}] = Registry.lookup(Tetrex.GameRegistry, player_id)

    %Game{
      board_pid: board_server,
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
      |> game_assigns()
      |> assign(board_server: board_server)
      |> assign(periodic_mover: periodic_mover)
      |> new_game()

    {:ok, socket}
  end

  @impl true
  def handle_event("start_game", _value, socket), do: {:noreply, start_game(socket)}

  @impl true
  def handle_event("keypress", %{"key" => "Enter"}, %{assigns: %{status: :game_over}} = socket) do
    # TODO: Don't pass these in here, use defaults from function
    BoardServer.new(
      socket.assigns.board_server,
      @board_height,
      @board_width,
      Enum.random(0..10_000_000)
    )

    {:noreply,
     socket
     |> new_game(true)
     |> game_assigns()}
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
          GameServer.update_lines_cleared(socket.assigns.game_server, &(&1 + lines_cleared))

          socket
          |> update_level()
          |> maybe_remove_blocking(lines_cleared)
          |> game_assigns()

        # Game over :-(
        _ ->
          socket
          |> game_over()
          |> game_assigns()
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
          |> game_assigns()

        # Game over :-(
        _ ->
          socket
          |> game_over()
          |> game_assigns()
      end

    {:noreply, socket}
  end

  defp try_move_down(socket) do
    case BoardServer.try_move_down(socket.assigns.board_server) do
      # Moved without collision
      {:moved, _, _} ->
        socket
        |> game_assigns()

      # Failed to move piece, which means it hit the bottom or another piece
      {_, preview, lines_cleared} when preview.active_tile_fits ->
        GameServer.update_lines_cleared(socket.assigns.game_server, &(&1 + lines_cleared))

        socket
        |> update_level()
        |> maybe_remove_blocking(lines_cleared)
        |> game_assigns()

      # Game over :-(
      _ ->
        socket
        |> game_over()
        |> game_assigns()
    end
  end

  defp game_over(socket) do
    # Stop sending periodic moves
    Periodic.stop_timer(socket.assigns.periodic_mover)

    GameServer.set_status(socket.assigns.game_server, :game_over)

    socket
    |> push_event("stop-audio", %{id: @theme_music_audio_id})
    |> push_event("play-audio", %{id: @game_over_audio_id})
    |> game_assigns()
  end

  defp start_game(%{assigns: %{game_server: game_server}} = socket) do
    # Start sending periodic moves
    Periodic.start_timer(socket.assigns.periodic_mover)

    GameServer.set_status(game_server, :playing)

    socket
    |> push_event("play-audio", %{id: @theme_music_audio_id})
  end

  defp new_game(socket, is_playing \\ false) do
    socket =
      socket
      |> update_level()
      |> push_event("stop-audio", %{id: @game_over_audio_id})

    socket =
      if is_playing do
        socket
        |> game_assigns()
        |> start_game()
      else
        GameServer.set_status(socket.assigns.game_server, :intro)

        socket
        |> game_assigns()
      end

    socket
  end

  defp maybe_remove_blocking(socket, lines_cleared) do
    if lines_cleared >= 4 do
      BoardServer.remove_blocking_row(socket.assigns.board_server)
    end

    socket
  end

  defp game_assigns(socket) do
    %Game{
      board_pid: board_server,
      lines_cleared: lines_cleared,
      status: status
    } = GameServer.game(socket.assigns.game_server)

    preview = BoardServer.preview(board_server)

    socket
    |> assign(:board, preview)
    |> assign(:lines_cleared, lines_cleared)
    |> assign(:status, status)
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
