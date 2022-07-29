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
end
