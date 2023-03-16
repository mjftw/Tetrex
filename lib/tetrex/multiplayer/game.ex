defmodule Tetrex.Multiplayer.Game do
  @type player_status :: :not_ready | :ready | :playing | :dead
  @type game_status :: :players_joining | :all_ready | :playing | :finished
  @type id :: String.t()

  @type t :: %__MODULE__{
          game_id: id(),
          players: [
            %{
              user_id: id(),
              board_pid: pid(),
              lines_cleared: non_neg_integer(),
              status: player_status(),
              online: boolean()
            }
          ],
          status: game_status(),
          periodic_mover_pid: pid()
        }

  @enforce_keys [:game_id, :players, :status, :periodic_mover_pid]
  defstruct [:game_id, :players, :status, :periodic_mover_pid]

  def user_in_game?(%__MODULE__{players: players}, user_id),
    do: Enum.any?(players, fn %{user_id: player_user_id} -> player_user_id == user_id end)
end
