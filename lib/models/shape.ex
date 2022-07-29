defmodule Tetrex.Shape do
  @enforce_keys [:squares, :rows, :cols]
  defstruct squares: %{}, rows: 0, cols: 0

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
  %Tetrex.Shape{
      squares: %{{0, 0} => :blue, {1, 0} => :blue, {2, 0} => :blue, {2, 1} => :blue},
      rows: 3,
      cols: 2
    }
  ```
  """
  @spec new([[atom() | nil]]) :: __MODULE__.t()
  def new(squares_2d) do
    shape =
      for {row, row_num} <- Stream.with_index(squares_2d),
          {square, col_num} when square != nil <- Stream.with_index(row),
          reduce: %__MODULE__{squares: %{}, rows: 0, cols: 0} do
        %__MODULE__{squares: squares, rows: rows, cols: cols} ->
          %__MODULE__{
            squares: Map.put(squares, {row_num, col_num}, square),
            rows: max(rows, row_num),
            cols: max(cols, col_num)
          }
      end

    # Need to add 1 to rows and cols to represent how many, rather than max indexes
    %__MODULE__{squares: shape.squares, rows: shape.rows + 1, cols: shape.cols + 1}
  end

  @spec move(__MODULE__.t(), coordinate()) :: __MODULE__.t()
  def move(shape, offset) do
    squares =
      shape.squares
      |> move_squares(offset)
      |> Map.new()

    %__MODULE__{squares: squares, rows: shape.rows, cols: shape.cols}
  end

  @doc """
  Rotate the shape around the origin
  """
  @spec rotate(__MODULE__.t(), angle()) :: __MODULE__.t()
  def rotate(shape, angle) do
    squares =
      shape.squares
      |> rotate_squares(angle)
      |> Map.new()

    {rows, cols} = rotate_dimensions({shape.rows, shape.cols}, angle)

    %__MODULE__{squares: squares, rows: rows, cols: cols}
  end

  @doc """
  Combine two Shapes. In the case of overlaps values from the second shape overwrite the first.
  """
  @spec merge(__MODULE__.t(), __MODULE__.t()) :: __MODULE__.t()
  def merge(shape1, shape2) do
    %__MODULE__{
      squares: Map.merge(shape1.squares, shape2.squares),
      rows: max(shape1.rows, shape2.rows),
      cols: max(shape1.cols, shape2.cols)
    }
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

  defp rotate_dimensions({rows, cols}, :clockwise90), do: {cols, rows}
  defp rotate_dimensions({rows, cols}, :clockwise180), do: {rows, cols}
  defp rotate_dimensions({rows, cols}, :clockwise270), do: {cols, rows}
end
