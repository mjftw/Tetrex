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

  @enforce_keys [:values]
  defstruct [:values]

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
  %Tetrex.SparseGrid{values: %{}}
  ```
  """
  @spec new() :: __MODULE__.t()
  def new(), do: %__MODULE__{values: %{}}

  def new(grid_values) when is_map(grid_values), do: %__MODULE__{values: grid_values}

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
  %Tetrex.SparseGrid{values: %{{0, 0} => :blue, {1, 0} => :blue, {2, 0} => :blue, {2, 1} => :blue}}
  ```
  """
  @spec new([[any() | nil]]) :: __MODULE__.t()
  def new(values_2d) do
    values_map =
      for {row, row_num} <- Stream.with_index(values_2d),
          {value, col_num} when value != nil <- Stream.with_index(row),
          into: %{},
          do: {{row_num, col_num}, value}

    new(values_map)
  end

  @doc """
  Create a rectangle grid filled with a given value.
  The top_left and bottom_right coordinates border the fill area, inclusive of the coordinates.
  """
  @spec fill(any(), {y(), x()}, {y(), x()}) :: __MODULE__.t()
  def fill(value, {top_left_y, top_left_x}, {bottom_right_y, bottom_right_x}) do
    values_map =
      for y <- top_left_y..bottom_right_y,
          x <- top_left_x..bottom_right_x,
          into: %{},
          do: {{y, x}, value}

    new(values_map)
  end

  @spec move(__MODULE__.t(), {y(), x()}) :: __MODULE__.t()
  def move(%__MODULE__{values: grid}, {offset_y, offset_x}) do
    grid
    |> move_grid({offset_y, offset_x})
    |> Map.new()
    |> new()
  end

  @doc """
  Rotate the grid around the origin.
  """
  @spec rotate(__MODULE__.t(), angle()) :: __MODULE__.t()
  def rotate(grid, :zero), do: grid

  def rotate(%__MODULE__{values: grid}, angle) do
    grid
    |> rotate_grid(angle)
    |> Map.new()
    |> new()
  end

  @doc """
  Rotate the grid around a specific point of rotation
  """
  @spec rotate(__MODULE__.t(), angle(), coordinate()) :: __MODULE__.t()
  def rotate(%__MODULE__{values: grid}, angle, {rotate_at_y, rotate_at_x}) do
    # Rotating around a point is the same as moving to the origin, rotating, and moving back
    grid
    |> move_grid({-rotate_at_y, -rotate_at_x})
    |> rotate_grid(angle)
    |> move_grid({rotate_at_y, rotate_at_x})
    |> Map.new()
    |> new()
  end

  @doc """
  Find the 4 corner coordinates bounding the grid
  """
  @spec corners(__MODULE__.t()) :: %{
          topleft: coordinate(),
          topright: coordinate(),
          bottomleft: coordinate(),
          bottomright: coordinate()
        }
  def corners(%__MODULE__{values: grid}) do
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
  @spec size(__MODULE__.t()) :: {y(), x()}
  def size(grid) do
    case corners(grid) do
      %{topright: {tr_y, tr_x}, bottomleft: {bl_y, bl_x}} -> {bl_y - tr_y, tr_x - bl_x}
    end
  end

  @doc """
  Detect whether two grids have values at the same coordinates
  """
  @spec overlaps?(__MODULE__.t(), __MODULE__.t()) :: boolean()
  def overlaps?(%__MODULE__{values: grid1}, %__MODULE__{values: grid2}) do
    !MapSet.disjoint?(MapSet.new(Map.keys(grid1)), MapSet.new(Map.keys(grid2)))
  end

  @doc """
  Detect whether a grid is withing a bounding box, denoted by top_left and bottom_right coordinates.
  """
  @spec within_bounds?(__MODULE__.t(), {y(), x()}, {y(), x()}) :: boolean()
  def within_bounds?(grid, {box_tl_y, box_tl_x}, {box_br_y, box_br_x}) do
    %{
      topleft: {tl_y, tl_x},
      bottomright: {br_y, br_x}
    } = corners(grid)

    tl_y >= box_tl_y &&
      tl_x >= box_tl_x &&
      br_x <= box_br_x &&
      br_y <= box_br_y
  end

  @doc """
  Combine two SparseGrids. In the case of overlaps vales from the second grid overwrite the first.
  """
  @spec merge(__MODULE__.t(), __MODULE__.t()) :: __MODULE__.t()
  def merge(%__MODULE__{values: grid1}, %__MODULE__{values: grid2}) do
    Map.merge(grid1, grid2)
    |> new()
  end

  @doc """
  Move a grid so that it aligns with another grid.
  """
  @spec align(__MODULE__.t(), __MODULE__.t(), alignment()) :: __MODULE__.t()
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
  @spec align(__MODULE__.t(), {y(), x()}, {y(), x()}, alignment()) :: __MODULE__.t()
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

# Need SparseGrid to be a struct before I can do this
defimpl Inspect, for: Tetrex.SparseGrid do
  def inspect(grid, opts) do
    str_grid =
      Enum.map(grid.values, fn {coord, value} -> {coord, to_string(value)} end)
      |> Map.new()

    max_value_str_width =
      Enum.reduce(str_grid, 0, fn {_, value_str}, max_str_width ->
        value_str
        |> String.length()
        |> max(max_str_width)
      end)

    %{
      topleft: {tl_y, tl_x},
      bottomright: {br_y, br_x}
    } = Tetrex.SparseGrid.corners(grid)

    col_indices =
      tl_x..br_x
      |> Enum.map(&to_string/1)

    row_indices =
      tl_y..br_y
      |> Enum.map(&to_string/1)

    max_col_index_str_len =
      Enum.reduce(col_indices, 0, fn col_index_str, max_str_width ->
        col_index_str
        |> String.length()
        |> max(max_str_width)
      end)

    max_row_index_str_len =
      Enum.reduce(row_indices, 0, fn row_index_str, max_str_width ->
        row_index_str
        |> String.length()
        |> max(max_str_width)
      end)

    row_left_padding = String.duplicate(" ", max_row_index_str_len)

    cell_width = max(max_col_index_str_len, max_value_str_width)

    value_filler = String.duplicate(" ", cell_width)

    pad_central = fn str, len ->
      str_len = String.length(str)

      cond do
        str_len < len ->
          pad_len = len - str_len

          String.duplicate(" ", div(pad_len, 2)) <>
            str <> String.duplicate(" ", div(pad_len, 2) + rem(pad_len, 2))

        true ->
          str
      end
    end

    pad_right = fn str, len ->
      str_len = String.length(str)

      cond do
        str_len < len ->
          pad_len = len - str_len

          String.duplicate(" ", pad_len) <> str

        true ->
          str
      end
    end

    col_indices_row_str =
      col_indices
      |> Enum.map(&(" " <> pad_central.(&1, cell_width) <> " "))
      |> Enum.join(" ")

    col_indices_row_str_capped =
      row_left_padding <> " " <> pad_right.("x", max_row_index_str_len) <> col_indices_row_str

    cols_strs =
      Enum.map(tl_y..br_y, fn y ->
        row_index_str =
          y
          |> to_string()
          |> pad_right.(max_row_index_str_len)

        row_str =
          Enum.map(tl_x..br_x, fn x ->
            padded_value_str =
              str_grid
              |> Map.get({y, x}, value_filler)
              |> pad_central.(cell_width)

            " " <> padded_value_str <> " "
          end)
          |> Enum.join("│")

        row_index_str <> " │" <> row_str <> "│"
      end)

    row_divider =
      String.duplicate("─", cell_width + 2)
      |> List.duplicate(br_x - tl_x + 1)
      |> Enum.join("┼")

    row_divider_capped = row_left_padding <> " ┼" <> row_divider <> "┤"

    row_top =
      String.duplicate("─", cell_width + 2)
      |> List.duplicate(br_x - tl_x + 1)
      |> Enum.join("┼")

    row_top_capped = String.slice(row_left_padding, 1..-1) <> "y" <> " ┼" <> row_top <> "┤"

    row_bottom =
      String.duplicate("─", cell_width + 2)
      |> List.duplicate(br_x - tl_x + 1)
      |> Enum.join("┴")

    row_bottom_capped = row_left_padding <> " ┴" <> row_bottom <> "┘"

    grid_str =
      cols_strs
      |> Enum.intersperse(row_divider_capped)
      |> Enum.join("\n")

    Enum.join(
      [col_indices_row_str_capped, row_top_capped, grid_str, row_bottom_capped],
      "\n"
    )
  end
end
