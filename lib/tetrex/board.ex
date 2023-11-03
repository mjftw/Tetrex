defmodule CarsCommercePuzzleAdventure.Board do
  alias CarsCommercePuzzleAdventure.SparseGrid
  alias CarsCommercePuzzleAdventure.Tetromino

  @type placement_error :: :collision | :out_of_bounds
  @type movement_result :: :moved | placement_error()

  @tile_bag_size 9999

  @blocking_tile :blocking

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

  @type board :: %__MODULE__{
          playfield: SparseGrid.sparse_grid(),
          playfield_height: non_neg_integer(),
          playfield_width: non_neg_integer(),
          active_tile: SparseGrid.sparse_grid(),
          next_tile: SparseGrid.sparse_grid(),
          hold_tile: SparseGrid.sparse_grid(),
          upcoming_tile_names: [Tetromino.name()]
        }

  @type board_preview :: %{
          playfield: SparseGrid.t(),
          playfield_height: non_neg_integer(),
          playfield_width: non_neg_integer(),
          next_tile: SparseGrid.t(),
          hold_tile: SparseGrid.t(),
          active_tile_fits: boolean()
        }

  @doc """
  Get a new board with a given height, width, and random seed (used for drawing tiles)
  """
  @spec new(non_neg_integer(), non_neg_integer(), integer()) :: board()
  def new(height, width, random_seed) do
    [active_tile_name | [next_tile_name | upcoming_tile_names]] =
      Tetromino.draw_randoms(@tile_bag_size, random_seed)

    %__MODULE__{
      playfield: SparseGrid.new(),
      playfield_height: height,
      playfield_width: width,
      active_tile: Tetromino.fetch!(active_tile_name),
      next_tile: Tetromino.fetch!(next_tile_name),
      hold_tile: nil,
      upcoming_tile_names: upcoming_tile_names
    }
    |> align_active_with_playfield()
  end

  @doc """
  Clear all rows that have been completed, shifting the remaining playfield values down to
  fill the gaps.
  Return value is {Board, number_of_lines_cleared}
  """
  @spec clear_completed_rows(board()) :: {board(), non_neg_integer()}
  def clear_completed_rows(board) do
    {new_playfield, num_rows_cleared} =
      Enum.reduce(
        0..(board.playfield_height - 1),
        {board.playfield, 0},
        fn row_num, {playfield, num_rows_cleared} ->
          row_start = {row_num, 0}
          row_end = {row_num, board.playfield_width - 1}

          row_filled = SparseGrid.filled?(playfield, row_start, row_end)

          blocking_row =
            playfield
            |> SparseGrid.mask(row_start, row_end)
            |> SparseGrid.all?(&(&1 == @blocking_tile))

          should_clear_row = row_filled && !blocking_row

          case {should_clear_row, row_num} do
            {false, _} ->
              # Row not filled, skip
              {playfield, num_rows_cleared}

            {true, 0} ->
              # Top row is filled, clear it
              new_playfield =
                playfield
                |> SparseGrid.clear(row_start, row_end)

              {new_playfield, num_rows_cleared + 1}

            {true, _} ->
              # Some row is filled, clear it and shift everything above down

              new_playfield =
                playfield
                |> SparseGrid.clear({0, 0}, row_end)
                |> SparseGrid.merge(
                  playfield
                  |> SparseGrid.clear(row_start, row_end)
                  |> SparseGrid.mask({0, 0}, row_end)
                  |> SparseGrid.move(:down, 1)
                )

              {new_playfield, num_rows_cleared + 1}
          end
        end
      )

    {%{board | playfield: new_playfield}, num_rows_cleared}
  end

  @doc """
  Move the active tile down on the playfield by one square.
  If doing so would cause it to collide with tiles on the playfield or it's at the bottom then fix
  the active_tile to the playfield and draw a new one.
  If fixing the active_tile to the playfield results in completed rows, these rows are cleared.
  The return value is a {status_atom, new_board, number_of_rows_cleared}
  """
  @spec try_move_active_down(board()) ::
          {movement_result(), board(), non_neg_integer()}
  def try_move_active_down(board) do
    case try_move_active_if_legal(board, &SparseGrid.move(&1, {1, 0})) do
      # Moved active tile down without a collision
      {:ok, new_board} ->
        {:moved, new_board, 0}

      {:error, error} when error in [:collision, :out_of_bounds] ->
        # Could not move active tile down, fix in place, draw a new tile, and clear any filled rows
        {new_board, num_rows_cleared} =
          board
          |> merge_active_tile()
          |> draw_next_tile()
          |> clear_completed_rows()

        {error, new_board, num_rows_cleared}
    end
  end

  @doc """
  Move the active tile down until it collides with another tile.
  If doing so would cause it to collide with tiles on the playfield or it's at the bottom then fix
  the active_tile to the playfield and draw a new one.
  If fixing the active_tile to the playfield results in completed rows, these rows are cleared.
  The return value is a {new_board, number_of_rows_cleared}
  """
  @spec drop_active(board()) :: board()
  def drop_active(board) do
    board
    |> drop_active_no_merge()
    |> merge_active_tile()
    |> draw_next_tile()
    |> clear_completed_rows()
  end

  defp drop_active_no_merge(board) do
    case try_move_active_if_legal(board, &SparseGrid.move(&1, {1, 0})) do
      {:ok, new_board} -> drop_active_no_merge(new_board)
      {:error, err} -> board
    end
  end

  @doc """
  Move the active_tile left on the playfield by one square.
  If doing so would result in a collision or the tile moving off the board the tile is not moved.
  """
  @spec try_move_active_left(board()) :: {movement_result(), board()}
  def try_move_active_left(board), do: try_move_active_sideways(board, -1)

  @doc """
  Move the active_tile right on the playfield by one square.
  If doing so would result in a collision or the tile moving off the board the tile is not moved.
  """
  @spec try_move_active_right(board()) :: {movement_result(), board()}
  def try_move_active_right(board), do: try_move_active_sideways(board, 1)

  @doc """
  Move the active tile into the hold slot.
  If the hold slot was empty a new tile is drawn.
  If hold slot was full, swap the hold and active tiles
  If swapping the hold and active tiles is not possible due to a collision, do not swap.
  """
  @spec hold_active(board()) :: board()
  def hold_active(board) do
    # Compute lazily as not needed in all branches
    active_at_origin = fn -> SparseGrid.align(board.active_tile, :top_left, {0, 0}, {0, 0}) end

    case board.hold_tile do
      nil ->
        # No hold tile, put active in hold slot and draw new active
        %{board | hold_tile: active_at_origin.()}
        |> draw_next_tile()

      _ ->
        # Swap the active and hold tiles
        case try_move_active_if_legal(
               board,
               fn _ -> SparseGrid.align(board.hold_tile, :top_centre, board.active_tile) end
             ) do
          {:ok, new_board} ->
            # hold tile fits on board
            %{new_board | hold_tile: active_at_origin.()}

          {:error, error} when error in [:collision, :out_of_bounds] ->
            # hold tile does not fit on board
            board
        end
    end
  end

  @doc """
  Attempt to rotate the active tile clockwise, first 90 degrees clockwise, then 180, then 270.
  If a rotation would cause a collision the next is tried.
  If no rotation is possible then the board is returned unchanged.
  """
  @spec rotate_active(board()) :: board()
  def rotate_active(board) do
    # Keep attempting to rotate until it works, or every rotation has been tried and failed
    result =
      with {:error, _} <-
             try_move_active_if_legal(
               board,
               &CarsCommercePuzzleAdventure.SparseGrid.rotate(&1, :clockwise90)
             ),
           {:error, _} <-
             try_move_active_if_legal(
               board,
               &CarsCommercePuzzleAdventure.SparseGrid.rotate(&1, :clockwise180)
             ),
           {:error, _} <-
             try_move_active_if_legal(
               board,
               &CarsCommercePuzzleAdventure.SparseGrid.rotate(&1, :clockwise270)
             ),
           do: :could_not_rotate

    case result do
      {:ok, new_board} -> new_board
      :could_not_rotate -> board
    end
  end

  @doc """
  Push the playfield up by adding a row to the bottom
  """
  @spec add_blocking_row(board()) :: board()
  def add_blocking_row(board) do
    blocking_row =
      SparseGrid.fill(
        @blocking_tile,
        {board.playfield_height - 1, 0},
        {board.playfield_height - 1, board.playfield_width - 1}
      )

    playfield =
      board.playfield
      |> SparseGrid.move({-1, 0})
      |> SparseGrid.merge(blocking_row)

    %__MODULE__{
      board
      | playfield: playfield
    }
  end

  @doc """
  Remove one blocking line from the bottom of the playfield, if there is one
  """
  @spec remove_blocking_row(board()) :: board()
  def remove_blocking_row(board) do
    has_blocking_row =
      board.playfield
      |> SparseGrid.mask(
        {board.playfield_height - 1, 0},
        {board.playfield_height - 1, board.playfield_width - 1}
      )
      |> SparseGrid.all?(&(&1 == @blocking_tile))

    if has_blocking_row do
      playfield =
        board.playfield
        |> SparseGrid.mask(
          {0, 0},
          {board.playfield_height - 2, board.playfield_width - 1}
        )
        |> SparseGrid.move({1, 0})

      %__MODULE__{
        board
        | playfield: playfield
      }
    else
      board
    end
  end

  @doc """
  Apply a transform function to the active tile, checking that doing so would
  cause it to collide with the playfield or be outside the playfield.
  """
  @spec try_move_active_if_legal(
          board(),
          (SparseGrid.sparse_grid() -> SparseGrid.sparse_grid())
        ) :: {:ok, board()} | {:error, placement_error()}
  def try_move_active_if_legal(board, transform_fn) do
    candidate_placement = transform_fn.(board.active_tile)

    collides_with_playfield = SparseGrid.overlaps?(candidate_placement, board.playfield)

    on_playfield =
      SparseGrid.within_bounds?(
        candidate_placement,
        {0, 0},
        {board.playfield_height - 1, board.playfield_width - 1}
      )

    cond do
      collides_with_playfield -> {:error, :collision}
      !on_playfield -> {:error, :out_of_bounds}
      true -> {:ok, %{board | active_tile: candidate_placement}}
    end
  end

  @doc """
  Build the flattened preview of the Board.
  This preview contains everything needed for a front end to display the Board.
  """
  @spec preview(board()) :: board_preview()
  def preview(board) do
    # FIXME: This check is not sufficient!
    # If a blocking row is added there may be an overlap where the tiles are pushed off the board,
    #  but active tile still fits.
    # Need additional check to see if this has happened, and put this info in preview.
    # Maybe change "active_tile_fits" to "tiles_fit_on_board" instead
    case SparseGrid.overlaps?(board.active_tile, board.playfield) do
      false ->
        %{active_tile: dropped} = drop_active_no_merge(board)

        playfield =
          dropped
          |> SparseGrid.replace(:drop_preview)
          |> SparseGrid.merge(board.playfield)
          |> SparseGrid.merge(board.active_tile)

        %{
          playfield: playfield,
          next_tile: board.next_tile,
          hold_tile: board.hold_tile,
          playfield_height: board.playfield_height,
          playfield_width: board.playfield_width,
          active_tile_fits: true
        }

      true ->
        new_board = try_move_active_up_until_fits(board)

        %{
          playfield: SparseGrid.merge(new_board.playfield, new_board.active_tile),
          next_tile: new_board.next_tile,
          hold_tile: new_board.hold_tile,
          playfield_height: board.playfield_height,
          playfield_width: board.playfield_width,
          active_tile_fits: false
        }
    end
  end

  defp merge_active_tile(board) do
    %{
      board
      | playfield: SparseGrid.merge(board.playfield, board.active_tile)
    }
  end

  @spec draw_next_tile(board()) :: board()
  defp draw_next_tile(board) do
    [next_tile_name | upcoming_tile_names] = board.upcoming_tile_names

    %{
      board
      | next_tile: Tetromino.fetch!(next_tile_name),
        upcoming_tile_names: upcoming_tile_names,
        active_tile: board.next_tile
    }
    |> align_active_with_playfield()
  end

  @spec align_active_with_playfield(board()) :: board()
  defp align_active_with_playfield(board) do
    %{
      board
      | active_tile:
          SparseGrid.align(
            board.active_tile,
            :top_centre,
            {0, 0},
            {board.playfield_height, board.playfield_width}
          )
    }
  end

  defp try_move_active_up_until_fits(board) do
    case SparseGrid.overlaps?(board.active_tile, board.playfield) do
      false ->
        board

      true ->
        %{
          board
          | active_tile:
              board.active_tile
              |> SparseGrid.move({-1, 0})
              |> SparseGrid.mask({0, 0}, {board.playfield_height - 1, board.playfield_width - 1})
        }
        |> try_move_active_up_until_fits()
    end
  end

  defp try_move_active_sideways(board, x_translation) do
    case try_move_active_if_legal(board, &SparseGrid.move(&1, {0, x_translation})) do
      {:ok, new_board} -> {:moved, new_board}
      {:error, error} when error in [:collision, :out_of_bounds] -> {error, board}
    end
  end
end
