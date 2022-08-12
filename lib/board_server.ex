defmodule Tetrex.Board.Server do
  use GenServer
  alias Tetrex.Board

  @type init_args :: [height: non_neg_integer(), width: non_neg_integer(), random_seed: integer()]

  # Client API

  @spec start_link(init_args()) :: pid()
  def start_link(board_opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, board_opts)
    pid
  end

  @spec preview(pid()) :: Board.board_preview()
  def preview(board_pid) do
    GenServer.call(board_pid, :preview)
  end

  @spec try_move_left(pid()) :: {Board.movement_result(), Board.board_preview()}
  def try_move_left(board_pid) do
    GenServer.call(board_pid, :try_move_left)
  end

  @spec try_move_right(pid()) :: {Board.movement_result(), Board.board_preview()}
  def try_move_right(board_pid) do
    GenServer.call(board_pid, :try_move_right)
  end

  @spec try_move_down(pid()) ::
          {Board.movement_result(), Board.board_preview(), non_neg_integer()}
  def try_move_down(board_pid) do
    GenServer.call(board_pid, :try_move_down)
  end

  @spec rotate(pid()) :: Board.board_preview()
  def rotate(board_pid) do
    GenServer.call(board_pid, :rotate)
  end

  @spec hold(pid()) :: Board.board_preview()
  def hold(board_pid) do
    GenServer.call(board_pid, :hold)
  end

  # Server callbacks

  @impl true
  @spec init(init_args()) ::
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

  @impl true
  def handle_cast(_, board) do
    {:noreply, board}
  end
end
