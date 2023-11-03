defmodule CarsCommercePuzzleAdventure.Users.User do
  @type t :: %__MODULE__{id: String.t(), username: String.t()}

  @enforce_keys [:id, :username]
  defstruct [:id, :username]
end
