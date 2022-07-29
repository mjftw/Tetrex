defmodule Tetrex.Shape do
  @enforce_keys [:squares, :rows, :cols]
  defstruct squares: %{}, rows: 0, cols: 0

  @doc """
  Create a new Shape from a 2d list of values.
  To leave a square empty, `nil` can be used.

  E.g.

  iex> Tetrex.Shape.new([
  ...>   [:blue, nil],
  ...>   [:blue, nil],
  ...>   [:blue, :blue],
  ...> ])
  %Tetrex.Shape{
      squares: %{{0, 0} => :blue, {1, 0} => :blue, {2, 0} => :blue, {2, 1} => :blue},
      rows: 2,
      cols: 1
    }
  """
  @spec new([[atom() | nil]]) :: __MODULE__.t()
  def new(squares_2d) do
    for {row, row_num} <- Stream.with_index(squares_2d),
        {square, col_num} when square != nil <- Stream.with_index(row),
        reduce: %__MODULE__{squares: %{}, rows: 0, cols: 0} do
      %__MODULE__{squares: squares, rows: rows} ->
        %__MODULE__{
          squares: Map.put(squares, {row_num, col_num}, square),
          rows: max(rows, row_num),
          # Latest col_num is always the max so no need to check
          cols: col_num
        }
    end
  end

  @spec move(__MODULE__.t(), {integer(), integer()}) :: __MODULE__.t()
  def move(shape, {offset_rows, offset_cols}) do
    squares =
      shape.squares
      |> Enum.map(fn {{row, col}, value} -> {{row + offset_rows, col + offset_cols}, value} end)
      |> Map.new()

    %__MODULE__{squares: squares, rows: shape.rows, cols: shape.cols}
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
end
