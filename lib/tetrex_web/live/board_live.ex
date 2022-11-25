defmodule TetrexWeb.BoardLive do
  use TetrexWeb, :live_view

  alias TetrexWeb.Components.BoardComponents

  @impl true
  def mount(_params, _session, socket) do
    # TODO: Define board outside and pass in - just for dev
    board = Tetrex.Board.new(20, 10, 3)
    preview = Tetrex.Board.preview(board)

    # TODO: Add width and height to Board.preview
    socket =
      socket
      |> assign(board: preview)
      |> assign(playfield_width: board.playfield_width)
      |> assign(playfield_height: board.playfield_height)

    {:ok, socket}
  end
end
