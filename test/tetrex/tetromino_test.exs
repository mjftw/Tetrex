defmodule CarsCommercePuzzleAdventure.Tetromino.Test do
  use ExUnit.Case

  alias CarsCommercePuzzleAdventure.Tetromino

  doctest CarsCommercePuzzleAdventure.SparseGrid

  test "draw_randoms/2 should draw the same list given the same seed" do
    draw1 = Tetromino.draw_randoms(100, -2232)
    draw2 = Tetromino.draw_randoms(100, -2232)

    assert draw1 == draw2
  end
end
