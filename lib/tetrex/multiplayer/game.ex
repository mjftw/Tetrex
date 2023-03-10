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
          status: :players_joining | :all_ready | :playing | :finished,
          periodic_mover_pid: pid()
        }

  @enforce_keys [:players, :status, :periodic_mover_pid]
  defstruct [:players, :status, :periodic_mover_pid]
end
