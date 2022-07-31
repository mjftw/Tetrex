defmodule Tetrex.LazySparseGrid do
  @moduledoc """
  Represents a SparseGrid with a number of transformations yet to be carried out.
  E.g. Rotation, Translation
  """

  alias Tetrex.SparseGrid
  @enforce_keys [:sparse_grid]
  defstruct [:sparse_grid, translation: {0, 0}, rotation: :zero, rotation_origin: {0, 0}]

  @doc """
  Apply rotation and translation transformations to get the final placed grid.
  """
  @spec transform(__MODULE__.t()) :: SparseGrid.sparse_grid()
  def transform(%__MODULE__{
        sparse_grid: sparse_grid,
        translation: translation,
        rotation: rotation,
        rotation_origin: rotation_origin
      }) do
    rotated =
      case rotation_origin do
        {0, 0} -> SparseGrid.rotate(sparse_grid, rotation)
        _ -> SparseGrid.rotate(sparse_grid, rotation, rotation_origin)
      end

    case translation do
      {0, 0} -> rotated
      _ -> SparseGrid.move(rotated, translation)
    end
  end
end
