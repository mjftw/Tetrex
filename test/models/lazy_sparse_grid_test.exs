defmodule Tetrex.LazySparseGrid.Test do
  use ExUnit.Case

  alias Tetrex.LazySparseGrid
  alias Tetrex.SparseGrid

  test "transform/1 should apply rotation" do
    lazy_grid = %LazySparseGrid{
      rotation: :clockwise90,
      sparse_grid:
        SparseGrid.new([
          [:l],
          [:l],
          [:l, :l]
        ])
    }

    expected =
      SparseGrid.new([
        [:l, :l, :l],
        [:l]
      ])
      |> SparseGrid.move({0, -2})

    assert LazySparseGrid.transform(lazy_grid) == expected
  end

  test "transform/1 should apply rotation around a given origin" do
    lazy_grid = %LazySparseGrid{
      rotation: :clockwise90,
      rotation_origin: {1, 1},
      sparse_grid:
        SparseGrid.new([
          [:l],
          [:l],
          [:l, :l]
        ])
    }

    expected =
      SparseGrid.new([
        [:l, :l, :l],
        [:l]
      ])

    assert LazySparseGrid.transform(lazy_grid) == expected
  end

  test "transform/1 should apply translation" do
    lazy_grid = %LazySparseGrid{
      translation: {2, 2},
      sparse_grid:
        SparseGrid.new([
          [:l],
          [:l],
          [:l, :l]
        ])
    }

    expected =
      SparseGrid.new([
        [:l],
        [:l],
        [:l, :l]
      ])
      |> SparseGrid.move({2, 2})

    assert LazySparseGrid.transform(lazy_grid) == expected
  end

  test "transform/1 should apply translation and rotation" do
    lazy_grid = %LazySparseGrid{
      translation: {2, 2},
      rotation: :clockwise180,
      sparse_grid:
        SparseGrid.new([
          [:l],
          [:l],
          [:l, :l]
        ])
    }

    expected =
      lazy_grid.sparse_grid
      |> SparseGrid.rotate(:clockwise180)
      |> SparseGrid.move({2, 2})

    assert LazySparseGrid.transform(lazy_grid) == expected
  end
end
