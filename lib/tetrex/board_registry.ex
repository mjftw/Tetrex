defmodule Tetrex.BoardRegistry do
  def user_has_board?(user_id) do
    user_id
    |> user_boards()
    |> Enum.count() > 0
  end

  def user_boards(user_id) do
    Registry.lookup(Tetrex.BoardRegistry, user_id)
  end
end
