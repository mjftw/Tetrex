defmodule TetrexWeb.BoardLive do
  use TetrexWeb, :live_view

  alias TetrexWeb.Components.BoardComponents
  alias Tetrex.BoardServer

  @board_height 20
  @board_width 10

  @impl true
  def mount(_params, _session, socket) do
    random_seed = Enum.random(0..10_000_000)

    # TODO Store state elsewhere and pass in
    {:ok, board_server} =
      BoardServer.start_link(height: @board_height, width: @board_width, random_seed: random_seed)

    preview = BoardServer.preview(board_server)

    socket =
      socket
      |> assign(board_server: board_server)
      |> assign(board: preview)

    {:ok, socket}
  end

  @impl true
  def handle_event("keypress", %{"key" => "ArrowDown"}, socket) do
    case BoardServer.try_move_down(socket.assigns.board_server) do
      {:moved, preview, _rows_cleared} -> {:noreply, assign(socket, :board, preview)}
      _ -> {:noreply, socket}
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
