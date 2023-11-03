defmodule CarsCommercePuzzleAdventure.IterUtils do
  @type t :: any()
  @doc """
  Helper utility that will repeatedly call the `predicate` function with the current index so long
  as it returns true.
  If true, the `get_next_index` generator function is called to get the index for the next
  iteration.
  The return value is `true` only if the generator function is exhausted and returns `:stop`

  This function is fast failing, as soon as the predicate returns `false` the function exits
  returning `false`.
  """
  @spec all((t() -> boolean()), t(), (t() -> {:continue, t()} | :stop)) :: boolean()
  def all(predicate, current_index, get_next_index) do
    if predicate.(current_index) do
      case get_next_index.(current_index) do
        {:continue, next_index} -> all(predicate, next_index, get_next_index)
        :stop -> true
      end
    else
      false
    end
  end
end
