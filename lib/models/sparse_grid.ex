defmodule Tetrex.SparseGrid do
  @moduledoc """
  Data structure for holding a 2d grid of values.
  Not every coordinate must have a value, in this sense it is a sparse grid.

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
  @type coordinate() :: coordinate()
  @type sparse_grid() :: %{coordinate() => any()}

  @doc """
  Create a new SparseGrid from a 2d list of values.
  To leave a value empty, `nil` can be used.

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
  def move(values, offset) do
    values
    |> move_values(offset)
    |> Map.new()
  end

  @doc """
  Rotate the shape around the origin
  """
  @spec rotate(sparse_grid(), angle()) :: sparse_grid()
  def rotate(values, angle) do
    values
    |> rotate_values(angle)
    |> Map.new()
  end

  @doc """
  Rotate the shape around a specific point of rotation
  """
  @spec rotate(sparse_grid(), angle(), coordinate()) :: sparse_grid()
  def rotate(values, angle, {rotate_at_x, rotate_at_y}) do
    # Rotating around a point is the same as moving to the origin, rotating, and moving back
    values
    |> move_values({-rotate_at_x, -rotate_at_y})
    |> rotate_values(angle)
    |> move_values({rotate_at_x, rotate_at_y})
    |> Map.new()
  end

  @doc """
  Combine two SparseGrids. In the case of overlaps values from the second shape overwrite the first.
  """
  @spec merge(sparse_grid(), sparse_grid()) :: sparse_grid()
  def merge(values1, values2) do
    Map.merge(values1, values2)
  end

  defp move_values(values, {x_offset, y_offset}) do
    Stream.map(values, fn {{col, row}, value} -> {{col + x_offset, row + y_offset}, value} end)
  end

  defp rotate_values(values, angle) do
    Stream.map(values, fn {coordinate, value} ->
      {rotate_coordinate(coordinate, angle), value}
    end)
  end

  defp rotate_coordinate({x, y}, :clockwise90), do: {y, -x}
  defp rotate_coordinate({x, y}, :clockwise180), do: {-x, -y}
  defp rotate_coordinate({x, y}, :clockwise270), do: {-y, x}
end
