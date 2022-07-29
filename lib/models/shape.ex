defmodule Tetrex.Shape do
  @enforce_keys [:squares, :rows, :cols]
  defstruct squares: %{}, rows: 0, cols: 0

  @spec new([[atom() | nil]]) :: Shape.t()
  def new(squares_2d) do
    for {row, row_num} <- Stream.with_index(squares_2d),
        {square, col_num} when square != nil <- Stream.with_index(row),
        reduce: %__MODULE__{squares: %{}, rows: 0, cols: 0} do
      %__MODULE__{squares: squares, rows: rows} ->
        %__MODULE__{
          squares: Map.merge(squares, %{{row_num, col_num} => square}),
          rows: max(rows, row_num),
          # Latest col_num is always the max so no need to check
          cols: col_num
        }
    end
  end

  @doc """
  Combine two Shapes. In the case of overlaps values from the second shape overwrite the first.
  """
  @spec merge(Shape.t(), Shape.t()) :: Shape.t()
  def merge(shape1, shape2) do
    %__MODULE__{
      squares: Map.merge(shape1.squares, shape2.squares),
      rows: max(shape1.rows, shape2.rows),
      cols: max(shape1.cols, shape2.cols)
    }
  end
end
