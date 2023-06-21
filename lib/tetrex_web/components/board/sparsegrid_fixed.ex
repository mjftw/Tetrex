defmodule TetrexWeb.Components.Board.SparseGridFixed do
  alias Tetrex.SparseGrid
  use TetrexWeb, :html

  attr(:sparsegrid, :map, required: true)
  attr(:height, :integer, required: true)
  attr(:width, :integer, required: true)

  def render(assigns) do
    ~H"""
    <div class={"grid-cols-#{@width} grid"}>
      <%= for y <- 0..@height-1, x <- 0..@width-1 do %>
        <.tile type={SparseGrid.get(@sparsegrid, y, x)} />
      <% end %>
    </div>
    """
  end

  attr(:type, :atom, required: true)

  defp tile(%{type: :red} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-red-400" />
    """
  end

  defp tile(%{type: :green} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-green-400" />
    """
  end

  defp tile(%{type: :blue} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-blue-400" />
    """
  end

  defp tile(%{type: :cyan} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-cyan-400" />
    """
  end

  defp tile(%{type: :yellow} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-yellow-400" />
    """
  end

  defp tile(%{type: :purple} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-purple-400" />
    """
  end

  defp tile(%{type: :orange} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-orange-400" />
    """
  end

  defp tile(%{type: :drop_preview} = assigns) do
    ~H"""
    <div class="h-7 w-7 border-2 border-solid border-slate-200 bg-none" />
    """
  end

  defp tile(%{type: :blocking} = assigns) do
    ~H"""
    <div class="border-1 h-7 w-7 border-solid border-slate-800 bg-slate-700" />
    """
  end

  defp tile(%{type: nil} = assigns) do
    ~H"""
    <div class="h-7 w-7 bg-none" />
    """
  end
end
