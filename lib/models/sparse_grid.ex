defmodule Tetrex.SparseGrid do
  @moduledoc """
  Data structure for holding a 2d grid of grid.
  Not every coordinate must have a grid, in this sense it is a sparse grid.
  Grid coordinates are written {col, row} or {y, x} with the origin (0, 0) is in the top left,
  as they would be for matrix notation.
  Coordinates can have negative values.

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

  @type angle() :: :clockwise90 | :clockwise180 | :clockwise270
  @type coordinate_x :: integer()
  @type coordinate_y :: integer()
  @type coordinate() :: {coordinate_y(), coordinate_x()}
  @type sparse_grid() :: %{coordinate() => any()}

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

  @spec move(sparse_grid(), coordinate()) :: sparse_grid()
  def move(grid, {offset_y, offset_x}) do
    grid
    |> move_grid({offset_y, offset_x})
    |> Map.new()
  end

  @doc """
  Rotate the shape around the origin
  """
  @spec rotate(sparse_grid(), angle()) :: sparse_grid()
  def rotate(grid, angle) do
    grid
    |> rotate_grid(angle)
    |> Map.new()
  end

  @doc """
  Rotate the shape around a specific point of rotation
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
  Combine two SparseGrids. In the case of overlaps vales from the second grid overwrite the first.
  """
  @spec merge(sparse_grid(), sparse_grid()) :: sparse_grid()
  def merge(grid1, grid2) do
    Map.merge(grid1, grid2)
  end

  defp move_grid(grid, {y_offset, x_offset}) do
    Stream.map(grid, fn {{y, x}, grid} -> {{y + y_offset, x + x_offset}, grid} end)
  end

  defp rotate_grid(grid, angle) do
    Stream.map(grid, fn {coordinate, grid} ->
      {rotate_coordinate(coordinate, angle), grid}
    end)
  end

  defp rotate_coordinate({y, x}, :clockwise90), do: {x, -y}
  defp rotate_coordinate({y, x}, :clockwise180), do: {-y, -x}
  defp rotate_coordinate({y, x}, :clockwise270), do: {-x, y}
end
