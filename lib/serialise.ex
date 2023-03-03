defmodule Serialise do
  def serialise(term) do
    term
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end

  def deserialise(str) when is_binary(str) do
    str
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()
  end
end
