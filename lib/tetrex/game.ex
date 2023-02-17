defmodule Tetrex.Game do
  @enforce_keys [:player_id, :lines_cleared, :score, :board_pid, :periodic_mover_pid, :status]
  defstruct [:player_id, :lines_cleared, :score, :board_pid, :periodic_mover_pid, :status]
end
