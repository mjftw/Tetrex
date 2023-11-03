defmodule CarsCommercePuzzleAdventure.SinglePlayer.Game do
  @type t :: %__MODULE__{
          user_id: String.t(),
          lines_cleared: non_neg_integer(),
          board_pid: pid(),
          periodic_mover_pid: pid(),
          status:
            :intro
            | :playing
            | :paused
            | :game_over
        }

  @enforce_keys [:user_id, :lines_cleared, :board_pid, :periodic_mover_pid, :status]
  defstruct [:user_id, :lines_cleared, :board_pid, :periodic_mover_pid, :status]
end
