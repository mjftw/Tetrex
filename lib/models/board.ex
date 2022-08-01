defmodule Tetrex.Board do
  alias Tetrex.SparseGrid
  alias Tetrex.LazySparseGrid
  alias Tetrex.Tetromino

  @type placement_error :: :collision | :out_of_bounds

  @tile_bag_size 9999

  @enforce_keys [
    :playfield,
    :playfield_height,
    :playfield_width,
    :active_tile,
    :next_tile,
    :hold_tile,
    :upcoming_tile_names
  ]
  defstruct [
    :playfield,
    :playfield_height,
    :playfield_width,
    :active_tile,
    :next_tile,
    :hold_tile,
    :upcoming_tile_names
  ]

  @spec new(non_neg_integer(), non_neg_integer(), integer()) :: __MODULE__.t()
  def new(height, width, random_seed) do
    [active_tile_name | [next_tile_name | upcoming_tile_names]] =
      Tetromino.draw_randoms(@tile_bag_size, random_seed)

    %__MODULE__{
      playfield: SparseGrid.new(),
      playfield_height: height,
      playfield_width: width,
      active_tile: Tetromino.tetromino!(active_tile_name),
      next_tile: Tetromino.tetromino!(next_tile_name),
      hold_tile: nil,
      upcoming_tile_names: upcoming_tile_names
    }
  end

  @doc """
  Attempt to place the active_tile on the playfield.
  An error is returned if the tile could not be placed due to the playfield already being full at
  that location.
  """
  @spec merge_active_draw_next(__MODULE__.t()) ::
          {:ok, __MODULE__.t()} | {:error, placement_error()}

  def merge_active_draw_next(board) do
    cond do
      !active_tile_fits_on_playfield?(board) ->
        {:error, :collision}

      true ->
        [next_tile_name | upcoming_tile_names] = board.upcoming_tile_names

        {:ok,
         %{
           board
           | next_tile: Tetromino.tetromino!(next_tile_name),
             upcoming_tile_names: upcoming_tile_names,
             active_tile: board.next_tile,
             playfield: SparseGrid.merge(board.playfield, board.active_tile)
         }}
    end
  end

  @doc """
  Move the active tile down on the playfield.
  If doing so would cause it to collide with tiles on the playfield or it's at the bottom then fix
  the active_tile to the playfield and draw a new one.
  """
  @spec move_active_down(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, :playfield_full}
  def move_active_down(board) do
    case move_active_if_legal(board, &SparseGrid.move(&1, {1, 0})) do
      {:ok, new_board} ->
        {:ok, new_board}

      {:error, error} when error == :collision or error == :out_of_bounds ->
        merge_active_draw_next(board)
    end
  end

  @doc """
  Apply a transform function to the active tile, checking that doing so would
  cause it to collide with the playfield or be outside the playfield.
  """
  @spec move_active_if_legal(
          __MODULE__.t(),
          (SparseGrid.sparse_grid() -> SparseGrid.sparse_grid())
        ) :: {:ok, __MODULE__.t()} | {:error, placement_error()}
  def move_active_if_legal(board, transform_fn) do
    candidate_placement = transform_fn.(board.active_tile)

    collides_with_playfield = SparseGrid.overlaps?(candidate_placement, board.playfield)

    on_playfield =
      SparseGrid.within_bounds?(
        candidate_placement,
        {0, 0},
        {board.playfield_height, board.playfield_width}
      )

    cond do
      collides_with_playfield -> {:error, :collision}
      !on_playfield -> {:error, :out_of_bounds}
      true -> {:ok, %{board | active_tile: candidate_placement}}
    end
  end

  defp active_tile_fits_on_playfield?(board) do
    candidate_placement =
      SparseGrid.align(
        board.active_tile,
        {0, 0},
        {board.playfield_height, board.playfield_width},
        :top_centre
      )

    !SparseGrid.overlaps?(candidate_placement, board.playfield)
  end
end
