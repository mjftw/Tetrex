defmodule Tetrex.Tetromino.Test do
  use ExUnit.Case

  alias Tetrex.Tetromino

  doctest Tetrex.SparseGrid

  test "draw_randoms/2 should draw a deterministic list of random tetrominos names" do
    drawn = Tetromino.draw_randoms(10, 42)

    expected = [:i, :s, :l, :z, :z, :o, :l, :i, :j, :i]

    assert drawn == expected
  end

  test "draw_randoms/2 should draw the same list given the same seed" do
    draw1 = Tetromino.draw_randoms(100, -2232)
    draw2 = Tetromino.draw_randoms(100, -2232)

    assert draw1 == draw2
  end
end
