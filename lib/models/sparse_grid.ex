defmodule Tetrex.SparseGrid do
  @moduledoc """
  Data structure for holding a 2d grid of grid.
  Not every coordinate must have a value, in this sense the grid is sparse.
  Grid coordinates are written {col, row} or {y, x} with the origin (0, 0) is in the top left,
  as they would be for matrix notation.
  Coordinates can have negative values.
  The grid is dynamically sized, meaning that each value written can change its dimensions.

  E.g.
  ```
      0   1   2   3   4
  0 |   | a |   |   |   |
    |---|---|---|---|---|
  1 |   |   | b |   |   |
    |---|---|---|---|---|
  2 |   |   | c | d |   |
    |---|---|---|---|---|
  3 |   |   |   | e |   |

  ```
  """

  @type(angle :: :zero, :clockwise90 | :clockwise180 | :clockwise270)
  @type alignment ::
          :top_left
          | :top_centre
          | :top_right
          | :centre_left
          | :centre
          | :centre_right
          | :bottom_left
          | :bottom_centre
          | :bottom_right
  @type x :: integer()
  @type y :: integer()
  @type coordinate :: {y(), x()}
  @type sparse_grid :: %{coordinate() => any()}

  @doc """
  Create a new empty SparseGrid
  E.g.
  ```
  iex> Tetrex.SparseGrid.new()
  %{}
  ```
  """
  @spec new() :: sparse_grid()
  def new(), do: %{}

  @doc """
  Create a new SparseGrid from a 2d list of values.
  To leave a grid empty, `nil` can be used.

  E.g.
  ```
  iex> Tetrex.SparseGrid.new([
  ...>   [:blue, nil],
  ...>   [:blue, nil],
  ...>   [:blue, :blue],
  ...> ])
  %{{0, 0} => :blue, {1, 0} => :blue, {2, 0} => :blue, {2, 1} => :blue}
  ```
  """
  @spec new([[any() | nil]]) :: sparse_grid()
  def new(values_2d) do
    for {row, row_num} <- Stream.with_index(values_2d),
        {value, col_num} when value != nil <- Stream.with_index(row),
        into: %{},
        do: {{row_num, col_num}, value}
  end

  @doc """
  Create a rectangle grid filled with a given value.
  The top_left and bottom_right coordinates border the fill area, inclusive of the coordinates.
  """
  @spec fill(any(), {y(), x()}, {y(), x()}) :: sparse_grid()
  def fill(value, {top_left_y, top_left_x}, {bottom_right_y, bottom_right_x}) do
    for y <- top_left_y..bottom_right_y,
        x <- top_left_x..bottom_right_x,
        into: %{},
        do: {{y, x}, value}
  end

  @spec move(sparse_grid(), {y(), x()}) :: sparse_grid()
  def move(grid, {offset_y, offset_x}) do
    grid
    |> move_grid({offset_y, offset_x})
    |> Map.new()
  end

  @doc """
  Rotate the grid around the origin.
  """
  @spec rotate(sparse_grid(), angle()) :: sparse_grid()
  def rotate(grid, :zero), do: grid

  def rotate(grid, angle) do
    grid
    |> rotate_grid(angle)
    |> Map.new()
  end

  @doc """
  Rotate the grid around a specific point of rotation
  """
  @spec rotate(sparse_grid(), angle(), coordinate()) :: sparse_grid()
  def rotate(grid, angle, {rotate_at_y, rotate_at_x}) do
    # Rotating around a point is the same as moving to the origin, rotating, and moving back
    grid
    |> move_grid({-rotate_at_y, -rotate_at_x})
    |> rotate_grid(angle)
    |> move_grid({rotate_at_y, rotate_at_x})
    |> Map.new()
  end

  @doc """
  Find the 4 corner coordinates bounding the grid
  """
  @spec corners(sparse_grid()) :: %{
          topleft: coordinate(),
          topright: coordinate(),
          bottomleft: coordinate(),
          bottomright: coordinate()
        }
  def corners(grid) do
    Enum.reduce(
      grid,
      %{
        topleft: {0, 0},
        topright: {0, 0},
        bottomleft: {0, 0},
        bottomright: {0, 0}
      },
      fn {{y, x}, _},
         %{
           topleft: {tl_y, tl_x},
           topright: {tr_y, tr_x},
           bottomleft: {bl_y, bl_x},
           bottomright: {br_y, br_x}
         } ->
        %{
          topleft: {min(tl_y, y), min(tl_x, x)},
          topright: {min(tr_y, y), max(tr_x, x)},
          bottomleft: {max(bl_y, y), min(bl_x, x)},
          bottomright: {max(br_y, y), max(br_x, x)}
        }
      end
    )
  end

  @doc """
  Find the width and height of the grid, returned as `{height, width}`.
  """
  @spec size(sparse_grid()) :: {y(), x()}
  def size(grid) do
    case __MODULE__.corners(grid) do
      %{topright: {tr_y, tr_x}, bottomleft: {bl_y, bl_x}} -> {bl_y - tr_y, tr_x - bl_x}
    end
  end

  @doc """
  Detect whether two grids have values at the same coordinates
  """
  @spec overlaps?(sparse_grid(), sparse_grid()) :: boolean()
  def overlaps?(grid1, grid2) do
    !MapSet.disjoint?(MapSet.new(Map.keys(grid1)), MapSet.new(Map.keys(grid2)))
  end

  @doc """
  Combine two SparseGrids. In the case of overlaps vales from the second grid overwrite the first.
  """
  @spec merge(sparse_grid(), sparse_grid()) :: sparse_grid()
  def merge(grid1, grid2) do
    Map.merge(grid1, grid2)
  end

  @doc """
  Move a grid so that it aligns with another grid.
  """
  @spec align(sparse_grid(), sparse_grid(), alignment()) :: sparse_grid()
  def align(grid_to_move, align_with_grid, alignment) do
    %{
      topleft: move_to_tl,
      bottomright: move_to_br
    } = corners(align_with_grid)

    align(grid_to_move, move_to_tl, move_to_br, alignment)
  end

  @doc """
  Move a grid to align it with a given bounding box,
  denoted by a top_left and bottom_right coordinate.
  """
  @spec align(sparse_grid(), {y(), x()}, {y(), x()}, alignment()) :: sparse_grid()
  def align(grid, top_left, bottom_right, alignment) do
    %{
      topleft: grid_tl,
      bottomright: grid_br
    } = corners(grid)

    {move_from_y, move_from_x} = alignment_coordinate(grid_tl, grid_br, alignment)
    {move_to_y, move_to_x} = alignment_coordinate(top_left, bottom_right, alignment)

    move(grid, {move_to_y - move_from_y, move_to_x - move_from_x})
  end

  defp alignment_coordinate({tl_y, tl_x}, {br_y, br_x}, alignment) do
    mid_x = div(br_x - tl_x, 2)
    mid_y = div(br_y - tl_y, 2)

    case alignment do
      :top_left -> {tl_y, tl_x}
      :top_centre -> {tl_y, mid_x}
      :top_right -> {tl_y, br_x}
      :centre_left -> {mid_y, tl_x}
      :centre -> {mid_y, mid_x}
      :centre_right -> {mid_y, br_x}
      :bottom_left -> {br_y, tl_x}
      :bottom_centre -> {br_y, mid_x}
      :bottom_right -> {br_y, br_x}
    end
  end

  defp move_grid(grid, {y_offset, x_offset}) do
    Stream.map(grid, fn {{y, x}, grid} -> {{y + y_offset, x + x_offset}, grid} end)
  end

  defp rotate_grid(grid, angle) do
    Stream.map(grid, fn {coordinate, grid} ->
      {rotate_coordinate(coordinate, angle), grid}
    end)
  end

  defp rotate_coordinate({y, x}, :zero), do: {y, x}
  defp rotate_coordinate({y, x}, :clockwise90), do: {x, -y}
  defp rotate_coordinate({y, x}, :clockwise180), do: {-y, -x}
  defp rotate_coordinate({y, x}, :clockwise270), do: {-x, y}
end
