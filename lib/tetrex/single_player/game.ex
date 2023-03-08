defmodule Tetrex.SinglePlayer.Game do
  @type t :: %__MODULE__{
          lines_cleared: non_neg_integer(),
          board_pid: pid(),
          periodic_mover_pid: pid(),
          status:
            :intro
            | :playing
            | :paused
            | :game_over
        }

  @enforce_keys [:lines_cleared, :board_pid, :periodic_mover_pid, :status]
  defstruct [:lines_cleared, :board_pid, :periodic_mover_pid, :status]
end
