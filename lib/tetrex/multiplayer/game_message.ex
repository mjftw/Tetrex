defmodule Tetrex.Multiplayer.GameMessage do
  alias Tetrex.Multiplayer.Game
  alias Tetrex.Board

  @type t :: %__MODULE__{
          players: %{
            String.t() => %{
              board_preview: Board.board_preview(),
              lines_cleared: non_neg_integer(),
              status: Game.player_status(),
              online: boolean()
            }
          },
          status: Game.game_status()
        }

  @enforce_keys [:players, :status]
  defstruct [:players, :status]
end
