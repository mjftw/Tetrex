defmodule Tetrex.Tetromino do
  @moduledoc """
  Official Tetromino shapes, names, and colours.
  As described on the Tetris wiki: https://tetris.wiki/Tetromino
  """

  alias Tetrex.SparseGrid

  @type colour :: :red | :green | :blue | :cyan | :yellow | :purple | :grey
  @type name :: :i | :o | :t | :s | :z | :j | :l

  @tetrominos %{
    i:
      SparseGrid.new([
        [:cyan],
        [:cyan],
        [:cyan],
        [:cyan]
      ]),
    o:
      SparseGrid.new([
        [:yellow, :yellow],
        [:yellow, :yellow]
      ]),
    t:
      SparseGrid.new([
        [nil, :purple, nil],
        [:purple, :purple, :purple]
      ]),
    s:
      SparseGrid.new([
        [nil, :green, :green],
        [:green, :green, nil]
      ]),
    z:
      SparseGrid.new([
        [:red, :red, nil],
        [nil, :red, :red]
      ]),
    j:
      SparseGrid.new([
        [:blue],
        [:blue, :blue, :blue]
      ]),
    l:
      SparseGrid.new([
        [nil, nil, :orange],
        [:orange, :orange, :orange]
      ])
  }

  @doc """
  Get a map of all tetromino names and grids.
  """
  @spec tetrominos() :: %{name() => %{SparseGrid.coordinate() => colour()}}
  def tetrominos(), do: @tetrominos

  @doc """
  Fetch the tetromino with the given name.
  An exception is raised if no tetromino with matching name exists.
  """
  @spec tetromino!(name()) :: SparseGrid.sparse_grid()
  def tetromino!(name), do: Map.fetch!(@tetrominos, name)

  # Would prefer to draw tiles from an infinite lazy stream rather than computing eagerly.
  # When playing Tetris Battles we want both players to draw the same sequence of tiles to make the
  #  game fair.
  # There is an issue with this though, since Erlang uses a global random number generator,
  #  if both games are drawing tiles using the same random number generator, they will draw
  #  different tiles.
  # The ideal way to deal with this would be to have each game have its own random number generator
  #  to use to draw tiles, each started with the same random seed. This ensures that tiles can be
  #  drawn independently but still follow the same sequence.
  # As a workaround for only having a single source of randomness, a large number of tiles can be
  #  drawn up front, ensuring anyone using this list of tiles has the same sequence. It's not ideal
  #  at all but it will do for now.
  @doc """
  Draw a list of random Tetrominos.
  """
  @spec draw_randoms(non_neg_integer(), integer()) :: [{name(), SparseGrid.sparse_grid()}]
  def draw_randoms(number, random_seed) do
    :rand.seed(:exsss, random_seed)

    names = Map.keys(@tetrominos)

    Stream.repeatedly(fn -> Enum.random(names) end)
    |> Stream.take(number)
    |> Enum.to_list()
  end
end
