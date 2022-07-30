defmodule Tetrex.Shape do
  @type angle() :: :clockwise90 | :clockwise180 | :clockwise270
  @type coordinate() :: coordinate()
  @type placed_values() :: %{coordinate() => any()}

  @doc """
  Create a new Shape from a 2d list of values.
  To leave a square empty, `nil` can be used.

  E.g.
  ```
  iex> Tetrex.Shape.new([
  ...>   [:blue, nil],
  ...>   [:blue, nil],
  ...>   [:blue, :blue],
  ...> ])
  %{{0, 0} => :blue, {1, 0} => :blue, {2, 0} => :blue, {2, 1} => :blue}
  ```
  """
  @spec new([[any() | nil]]) :: placed_values()
  def new(squares_2d) do
    for {row, row_num} <- Stream.with_index(squares_2d),
        {square, col_num} when square != nil <- Stream.with_index(row),
        into: %{},
        do: {{row_num, col_num}, square}
  end

  @spec move(placed_values(), coordinate()) :: placed_values()
  def move(squares, offset) do
    squares
    |> move_squares(offset)
    |> Map.new()
  end

  @doc """
  Rotate the shape around the origin
  """
  @spec rotate(placed_values(), angle()) :: placed_values()
  def rotate(squares, angle) do
    squares
    |> rotate_squares(angle)
    |> Map.new()
  end

  @doc """
  Rotate the shape around a specific point of rotation
  """
  @spec rotate(placed_values(), angle(), coordinate()) :: placed_values()
  def rotate(squares, angle, {rotate_at_x, rotate_at_y}) do
    # Rotating around a point is the same as moving to the origin, rotating, and moving back
    squares
    |> move_squares({-rotate_at_x, -rotate_at_y})
    |> rotate_squares(angle)
    |> move_squares({rotate_at_x, rotate_at_y})
    |> Map.new()
  end

  @doc """
  Combine two Shapes. In the case of overlaps values from the second shape overwrite the first.
  """
  @spec merge(placed_values(), placed_values()) :: placed_values()
  def merge(squares1, squares2) do
    Map.merge(squares1, squares2)
  end

  defp move_squares(squares, {x_offset, y_offset}) do
    Stream.map(squares, fn {{col, row}, value} -> {{col + x_offset, row + y_offset}, value} end)
  end

  defp rotate_squares(squares, angle) do
    Stream.map(squares, fn {coordinate, value} ->
      {rotate_coordinate(coordinate, angle), value}
    end)
  end

  defp rotate_coordinate({x, y}, :clockwise90), do: {y, -x}
  defp rotate_coordinate({x, y}, :clockwise180), do: {-x, -y}
  defp rotate_coordinate({x, y}, :clockwise270), do: {-y, x}
end
