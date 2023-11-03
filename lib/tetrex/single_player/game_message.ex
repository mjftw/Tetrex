defmodule CarsCommercePuzzleAdventure.SinglePlayer.GameMessage do
  @enforce_keys [:game_pid, :lines_cleared, :status, :board_preview]
  defstruct [:game_pid, :lines_cleared, :status, :board_preview]
end
