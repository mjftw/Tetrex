defmodule Tetrex.Game do
  @enforce_keys [:lines_cleared, :board_pid, :periodic_mover_pid, :status]
  defstruct [:lines_cleared, :board_pid, :periodic_mover_pid, :status]
end
