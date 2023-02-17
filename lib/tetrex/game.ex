defmodule Tetrex.Game do
  @enforce_keys [:player_id, :lines_cleared, :score, :board_pid, :periodic_mover_pid, :state]
  defstruct [:player_id, :lines_cleared, :score, :board_pid, :periodic_mover_pid, :state]
end
