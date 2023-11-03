defmodule CarsCommercePuzzleAdventure.Multiplayer.GameMessage do
  alias CarsCommercePuzzleAdventure.Multiplayer.Game
  alias CarsCommercePuzzleAdventure.Board

  @type id :: String.t()

  @type t :: %__MODULE__{
          game_id: String.t(),
          players: [
            {
              id(),
              %{
                board_preview: Board.board_preview(),
                lines_cleared: non_neg_integer(),
                status: Game.player_status(),
                online: boolean()
              }
            }
          ],
          status: Game.game_status()
        }

  @enforce_keys [:game_id, :players, :status]
  defstruct [:game_id, :players, :status]

  def player_in_game?(%__MODULE__{players: players}, player_id) do
    Enum.find(players, fn {id, _} -> id == player_id end)
  end
end
