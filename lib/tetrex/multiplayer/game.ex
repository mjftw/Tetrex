defmodule Tetrex.Multiplayer.Game do
  @type t :: %__MODULE__{
          players: %{
            String.t() => %{
              board_pid: pid(),
              lines_cleared: non_neg_integer(),
              status: :ready | :playing | :dead,
              online: boolean()
            }
          },
          status: :awaiting_start | :playing | :finished,
          periodic_mover_pid: pid()
        }

  @enforce_keys [:players, :status]
  defstruct [:players, :status]
end
