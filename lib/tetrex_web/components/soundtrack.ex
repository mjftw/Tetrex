defmodule TetrexWeb.Components.Soundtrack do
  use TetrexWeb, :live_component

  attr :id, :string, required: true
  attr :src, :string, required: true

  def background(assigns) do
    ~H"""
    <audio id={@id} loop>
      <source src={@src} type="audio/mpeg" />
    </audio>
    """
  end

  attr :id, :string, required: true
  attr :src, :string, required: true

  def effect(assigns) do
    ~H"""
    <audio id={@id}>
      <source src={@src} type="audio/mpeg" />
    </audio>
    """
  end
end
