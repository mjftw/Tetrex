defmodule Tetrex.Board.Server do
  use GenServer
  alias Tetrex.Board

  @impl true
  @spec init(height: non_neg_integer(), width: non_neg_integer(), random_seed: integer()) ::
          {:ok, %Tetrex.Board{}}
  def init(board_opts \\ []) do
    defaults = [height: 20, width: 10, random_seed: Enum.random(0..10_000_000)]
    options = Keyword.merge(defaults, board_opts)

    {:ok,
     Board.new(
       Keyword.fetch!(options, :height),
       Keyword.fetch!(options, :width),
       Keyword.fetch!(options, :random_seed)
     )}
  end

  @impl true
  def handle_call(:preview, _from, board) do
    preview = Board.preview(board)

    {:reply, preview, board}
  end

  @impl true
  def handle_call(:try_move_left, _from, board) do
    {status, new_board} = Board.try_move_active_left(board)
    preview = Board.preview(new_board)

    {:reply, {status, preview}, new_board}
  end

  @impl true
  def handle_call(:try_move_right, _from, board) do
    {status, new_board} = Board.try_move_active_right(board)
    preview = Board.preview(new_board)

    {:reply, {status, preview}, new_board}
  end

  @impl true
  def handle_call(:try_move_down, _from, board) do
    {status, new_board, num_lines_cleared} = Board.try_move_active_down(board)
    preview = Board.preview(new_board)

    {:reply, {status, preview, num_lines_cleared}, new_board}
  end

  @impl true
  def handle_call(:rotate, _from, board) do
    new_board = Board.rotate_active(board)
    preview = Board.preview(new_board)

    {:reply, preview, new_board}
  end

  @impl true
  def handle_call(:hold, _from, board) do
    new_board = Board.hold_active(board)
    preview = Board.preview(new_board)

    {:reply, preview, new_board}
  end

  @impl true
  def handle_call(_, _from, board) do
    {:reply, :unknown_command, board}
  end
end
