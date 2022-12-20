defmodule TetrexWeb.Components.Soundtrack do
  use TetrexWeb, :component

  def background(assigns) do
    ~H"""
      <audio id={@id} muted loop>
        <source src={@src} type="audio/mpeg">
      </audio>
    """
  end
end
