# Tasks Todo

## Data layer

### Create data structures for Shape

A `Shape` represents a group of squares, each with a colour.

A `Shape` can be constructed from a 2d list of atoms like so:

```elixir
iex> red_tee = Shape.new([
  [nil,  :red, nil],
  [:red, :red, :red],
])

iex> blue_l = Shape.new([
  [:blue, nil],
  [:blue, nil],
  [:blue, :blue],
])

iex> green_square = Shape.new([
  [:green, :green],
  [:green, :green],
])
```

Internally it is represented as a Map of coordinates to colours as this allows for more efficient
storage of sparse grids, but this is an unimportant implementation detail.

A `Shape` is used to represent the current Grid, as well as any Tetrominos that are being moved.

### Create API for Shape

We need an API to:

* Rotate a `Shape` around a given x, y index
  * Used for rotating a Tetromino
  * Needs to rotate around a given index so that a `Shape` can rotate around it's closest point to the middle
* Layer one `Shape` over another `Shape`, with a given x, y offset
  * Essentially pretends the `Shape`s are the same size, and then overlays one on top of the other
  * This is used to put a Tetromino on the Playfield
* Check if layering the shapes causes a collision
  * Using this we can propose moving or rotating a `Shape` and see if it would collide with the other
  * This is useful for checking whether a Tetromino can be rotated or moved down on the Playfield

## Game layer

This layer adds all the game rules required for playing a single player game of Tetris.

Required actions:

* Create empty board
* Draw new Tetromino at random
* Add a blocking line to the bottom of the Playfield
* Clear a line from the bottom of the Playfield


## Sockets layer

Uses Phoenix channels

## Client interaction

Client -> Server actions:

* Join game
  * Game begins once 2 players have joined
* Send command
  * Request to move, rotate, hold, etc a Tetromino

Server -> Client actions:

* Send game state
