defmodule TetrexWeb.Components.Soundtrack do
  use TetrexWeb, :live_component

  def background(assigns) do
    ~H"""
    <audio id={@id} muted loop>
      <source src={@src} type="audio/mpeg" />
    </audio>
    """
  end

  def effect(assigns) do
    ~H"""
    <audio id={@id} muted>
      <source src={@src} type="audio/mpeg" />
    </audio>
    """
  end
end
