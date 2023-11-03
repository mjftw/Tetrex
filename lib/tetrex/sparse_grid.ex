defmodule CarsCommercePuzzleAdventure.SparseGrid do
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
  @type sparse_grid :: %__MODULE__{values: %{coordinate() => any()}}

  @doc """
  Create a new empty SparseGrid
  E.g.
  ```
  iex> CarsCommercePuzzleAdventure.SparseGrid.new()
  %CarsCommercePuzzleAdventure.SparseGrid{values: %{}}
  ```
  """
  @spec new() :: sparse_grid()
  def new(), do: %__MODULE__{values: %{}}

  def new(grid_values) when is_map(grid_values), do: %__MODULE__{values: grid_values}

  @doc """
  Create a new SparseGrid from a 2d list of values.
  To leave a grid empty, `nil` can be used.

  E.g.
  ```
  iex> CarsCommercePuzzleAdventure.SparseGrid.new([
  ...>   [:blue, nil],
  ...>   [:blue, nil],
  ...>   [:blue, :blue],
  ...> ])
  %CarsCommercePuzzleAdventure.SparseGrid{values: %{{0, 0} => :blue, {1, 0} => :blue, {2, 0} => :blue, {2, 1} => :blue}}
  ```
  """
  @spec new([[any() | nil]]) :: sparse_grid()
  def new(values_2d) do
    values_map =
      for {row, row_num} <- Stream.with_index(values_2d),
          {value, col_num} when value != nil <- Stream.with_index(row),
          into: %{},
          do: {{row_num, col_num}, value}

    new(values_map)
  end

  @doc """
  Create an empty grid.
  """
  @spec empty() :: sparse_grid()
  def empty do
    new([])
  end

  @doc """
  Create a rectangle grid filled with a given value.
  The top_left and bottom_right coordinates border the fill area, inclusive of the coordinates.
  """
  @spec fill(any(), {y(), x()}, {y(), x()}) :: sparse_grid()
  def fill(value, {top_left_y, top_left_x}, {bottom_right_y, bottom_right_x}) do
    values_map =
      for y <- top_left_y..bottom_right_y,
          x <- top_left_x..bottom_right_x,
          into: %{},
          do: {{y, x}, value}

    new(values_map)
  end

  @spec move(sparse_grid(), {y(), x()}) :: sparse_grid()
  def move(%__MODULE__{values: grid}, {offset_y, offset_x}) do
    grid
    |> move_grid({offset_y, offset_x})
    |> Map.new()
    |> new()
  end

  @doc """
  Get the value at a given grid coordinate.
  Returns nil if no value present.
  """
  @spec get(sparse_grid(), y(), x()) :: any() | nil
  def get(grid, y, x), do: Map.get(grid.values, {y, x})

  @spec move(sparse_grid(), :up, non_neg_integer()) :: sparse_grid()
  def move(grid, :up, amount), do: move(grid, {-amount, 0})

  @spec move(sparse_grid(), :down, non_neg_integer()) :: sparse_grid()
  def move(grid, :down, amount), do: move(grid, {amount, 0})

  @spec move(sparse_grid(), :left, non_neg_integer()) :: sparse_grid()
  def move(grid, :left, amount), do: move(grid, {0, -amount})

  @spec move(sparse_grid(), :right, non_neg_integer()) :: sparse_grid()
  def move(grid, :right, amount), do: move(grid, {0, amount})

  @doc """
  Rotate the grid around the origin.
  """
  def rotate(grid, :zero), do: grid

  @spec rotate(sparse_grid(), angle()) :: sparse_grid()
  def rotate(grid, angle) do
    %{
      topleft: {top_before, left_before} = topleft,
      bottomright: bottomright
    } = corners(grid)

    centre = alignment_coordinate(topleft, bottomright, :centre)

    rotated = rotate(grid, angle, centre)

    %{topleft: {top_after, left_after}} = corners(rotated)

    # We are rotating around centre, so if we've translated we need to translate back
    move(rotated, {top_before - top_after, left_before - left_after})
  end

  @doc """
  Rotate the grid around a specific point of rotation
  """
  @spec rotate(sparse_grid(), angle(), coordinate()) :: sparse_grid()
  def rotate(grid, angle, {rotate_at_y, rotate_at_x}) do
    # Rotating around a point is the same as moving to the origin, rotating, and moving back
    new_grid =
      grid.values
      |> move_grid({-rotate_at_y, -rotate_at_x})
      |> rotate_grid(angle)
      |> move_grid({rotate_at_y, rotate_at_x})
      |> Map.new()
      |> new()
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
  def corners(%__MODULE__{values: grid}) do
    Enum.reduce(
      grid,
      nil,
      fn
        {{y, x}, _}, nil ->
          %{
            topleft: {y, x},
            topright: {y, x},
            bottomleft: {y, x},
            bottomright: {y, x}
          }

        {{y, x}, _},
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
    case corners(grid) do
      %{topright: {tr_y, tr_x}, bottomleft: {bl_y, bl_x}} -> {bl_y - tr_y, tr_x - bl_x}
    end
  end

  @doc """
  Find the number of rows in the grid.
  """
  @spec rows(sparse_grid()) :: integer()
  def rows(grid) do
    case size(grid) do
      {_, x} -> x
    end
  end

  @doc """
  Find the number of columns in the grid.
  """
  @spec cols(sparse_grid()) :: integer()
  def cols(grid) do
    case size(grid) do
      {y, _} -> y
    end
  end

  @doc """
  Detect whether two grids have values at the same coordinates
  """
  @spec overlaps?(sparse_grid(), sparse_grid()) :: boolean()
  def overlaps?(%__MODULE__{values: grid1}, %__MODULE__{values: grid2}) do
    !MapSet.disjoint?(MapSet.new(Map.keys(grid1)), MapSet.new(Map.keys(grid2)))
  end

  @doc """
  Detect whether a grid is withing a bounding box, denoted by top_left and bottom_right coordinates.
  """
  @spec within_bounds?(sparse_grid(), {y(), x()}, {y(), x()}) :: boolean()
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
  @spec merge(sparse_grid(), sparse_grid()) :: sparse_grid()
  def merge(%__MODULE__{values: grid1}, %__MODULE__{values: grid2}) do
    Map.merge(grid1, grid2)
    |> new()
  end

  def align(grid, _, _) when grid.values == %{}, do: grid
  def align(grid, _, align_with_grid) when align_with_grid.values == %{}, do: grid

  @doc """
  Move a grid so that it aligns with another grid.
  """
  @spec align(sparse_grid(), alignment(), sparse_grid()) :: sparse_grid()
  def align(grid_to_move, alignment, align_with_grid) do
    %{
      topleft: move_to_tl,
      bottomright: move_to_br
    } = corners(align_with_grid)

    align(grid_to_move, alignment, move_to_tl, move_to_br)
  end

  def align(grid, _, _, _) when grid.values == %{}, do: grid

  @doc """
  Move a grid to align it with a given bounding box,
  denoted by a top_left and bottom_right coordinate.
  """
  @spec align(sparse_grid(), alignment(), {y(), x()}, {y(), x()}) :: sparse_grid()
  def align(grid, alignment, top_left, bottom_right) do
    %{
      topleft: grid_tl,
      bottomright: grid_br
    } = corners(grid)

    {move_from_y, move_from_x} = alignment_coordinate(grid_tl, grid_br, alignment)
    {move_to_y, move_to_x} = alignment_coordinate(top_left, bottom_right, alignment)

    move(grid, {move_to_y - move_from_y, move_to_x - move_from_x})
  end

  @doc """
  Delete all entries from the grid that are within the bounding box (inclusive of edge coordinates).
  The bounding box is denoted by the coordinates of the top_left and bottom_right points.
  """
  @spec clear(sparse_grid(), {y(), x()}, {y(), x()}) :: sparse_grid()
  def clear(%__MODULE__{values: grid}, top_left, bottom_right) do
    grid
    |> Enum.filter(fn {coord, _} -> !coordinate_in_bounds(coord, top_left, bottom_right) end)
    |> Map.new()
    |> new()
  end

  @doc """
  Delete all entries from the grid that are outside the bounding box (inclusive of edge coordinates).
  The bounding box is denoted by the coordinates of the top_left and bottom_right points.
  """
  @spec mask(sparse_grid(), {y(), x()}, {y(), x()}) :: sparse_grid()
  def mask(%__MODULE__{values: grid}, top_left, bottom_right) do
    grid
    |> Enum.filter(fn {coord, _} -> coordinate_in_bounds(coord, top_left, bottom_right) end)
    |> Map.new()
    |> new()
  end

  @doc """
  Replace all entries in the grid with a given value
  """
  @spec replace(sparse_grid(), any()) :: sparse_grid()
  def replace(grid, value) do
    grid.values
    |> Enum.map(fn {coord, _} -> {coord, value} end)
    |> Map.new()
    |> new()
  end

  @doc """
  Check whether all grid cells in a given bounding box have a value.
  """
  @spec filled?(sparse_grid(), {y(), x()}, {y(), x()}) :: boolean()
  def filled?(grid, top_left, bottom_right) do
    {min_y, min_x} = top_left
    {max_y, max_x} = bottom_right

    CarsCommercePuzzleAdventure.IterUtils.all(
      &Map.has_key?(grid.values, &1),
      {min_y, min_x},
      &next_coordinate_generator(&1, min_x, {max_y, max_x})
    )
  end

  @doc """
  Runs a given predicate function on every element in the grid and returns
  true only if predicate returns true for every element.
  The predicate function can either one argument, the value to test, or two,
  the coordinate and value to test.
  """
  @spec all?(sparse_grid(), (any() -> boolean())) :: boolean()
  def all?(grid, predicate) when is_function(predicate, 1) do
    Enum.all?(grid.values, fn {_coord, value} -> predicate.(value) end)
  end

  @spec all?(sparse_grid(), (coordinate(), any() -> boolean())) :: boolean()
  def all?(grid, predicate) when is_function(predicate, 2) do
    Enum.all?(grid.values, fn {coord, value} -> predicate.(coord, value) end)
  end

  @spec next_coordinate_generator(coordinate(), {y(), x()}, {y(), x()}) ::
          {:continue, coordinate()} | :stop
  defp next_coordinate_generator({y, x}, min_x, {max_y, max_x}) do
    cond do
      y >= max_y && x >= max_x -> :stop
      x < max_x -> {:continue, {y, x + 1}}
      y < max_y -> {:continue, {y + 1, min_x}}
    end
  end

  @spec alignment_coordinate(coordinate(), coordinate(), alignment()) :: coordinate()
  defp alignment_coordinate({tl_y, tl_x}, {br_y, br_x}, alignment) do
    mid_x = tl_x + div(br_x - tl_x, 2)
    mid_y = tl_y + div(br_y - tl_y, 2)

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

  @spec coordinate_in_bounds(coordinate(), {y(), x()}, {y(), x()}) :: boolean()
  defp coordinate_in_bounds({y, x}, {box_tl_y, box_tl_x}, {box_br_y, box_br_x}) do
    box_tl_y <= y && y <= box_br_y &&
      box_tl_x <= x && x <= box_br_x
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

defimpl Inspect, for: CarsCommercePuzzleAdventure.SparseGrid do
  def inspect(grid, _opts) when grid.values == %{}, do: "<Empty SparseGrid>"

  def inspect(grid, _opts) do
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
    } = CarsCommercePuzzleAdventure.SparseGrid.corners(grid)

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

    col_indices_row_str_capped = row_left_padding <> " " <> "x" <> col_indices_row_str

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

    "\n" <>
      Enum.join(
        [col_indices_row_str_capped, row_top_capped, grid_str, row_bottom_capped],
        "\n"
      )
  end
end
