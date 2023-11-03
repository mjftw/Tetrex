defmodule CarsCommercePuzzleAdventureWeb.Components.Soundtrack do
  use CarsCommercePuzzleAdventureWeb, :live_component

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
