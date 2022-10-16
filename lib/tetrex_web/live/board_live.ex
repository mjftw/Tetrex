defmodule TetrexWeb.BoardLive do
  use TetrexWeb, :live_view

  alias TetrexWeb.Components.Board

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
