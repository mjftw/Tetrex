defmodule TetrexWeb.Components.BoardComponents do
  use TetrexWeb, :html
  alias Tetrex.SparseGrid

  @doc """
  Board component. Assumes board size is 10x20.
  Have to hard code this rather than passing as attrs as Tailwind CSS
  cannot handle dynamic classes due to JIT compilation.
  This means you cannot do "grid-cols-# {num_cols}".
  """
  attr(:sparsegrid, :map, required: true)

  def board(assigns) do
    ~H"""
    <div class="grid grid-cols-10">
      <%= for y <- 0..19, x <- 0..9 do %>
        <.tile type={SparseGrid.get(@sparsegrid, y, x)} />
      <% end %>
    </div>
    """
  end

  @doc """
  Single tile box component. Assumes tile needs 4x4 grid to fit
  Have to hard code this rather than passing as attrs as Tailwind CSS
  cannot handle dynamic classes due to JIT compilation.
  This means you cannot do "grid-cols-# {num_cols}".
  """
  attr(:sparsegrid, :map, required: true)

  def single_tile(assigns) do
    ~H"""
    <% sparsegrid = centre_single_tile(@sparsegrid || SparseGrid.empty()) %>
    <div class="grid grid-cols-4">
      <%= for y <- 0..3, x <- 0..3 do %>
        <.tile type={SparseGrid.get(sparsegrid, y, x)} />
      <% end %>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:sparsegrid, :map, required: true)

  def single_tile_box(assigns) do
    ~H"""
    <div class={"#{box_default_styles()} p-2"}>
      <%= @title %> <.single_tile sparsegrid={@sparsegrid} />
    </div>
    """
  end

  attr(:board, :map, required: true)

  def next_tile_box(assigns) do
    ~H"""
    <.single_tile_box title="Next" sparsegrid={@board.next_tile} />
    """
  end

  attr(:board, :map, required: true)

  def hold_tile_box(assigns) do
    ~H"""
    <.single_tile_box title="Hold" sparsegrid={@board.hold_tile} />
    """
  end

  attr(:board, :map, required: true)

  def playfield(assigns) do
    ~H"""
    <div class={box_default_styles()}>
      <.board sparsegrid={@board.playfield} />
    </div>
    """
  end

  attr(:score, :integer, required: true)

  def score_box(assigns) do
    ~H"""
    <div class={"#{box_default_styles()} p-2 text-xl"}>
      Score: <%= @score %>
    </div>
    """
  end

  slot :inner_block, required: true

  def single_player_game_box(assigns) do
    ~H"""
    <div class="flex flex-col items-center bg-teal-500 pb-5">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :is_dead, :boolean, required: false, default: false
  slot :inner_block, required: true

  def multiplayer_game(assigns) do
    ~H"""
    <div class={"#{if @is_dead, do: "bg-slate-400", else: " bg-teal-500 "} flex flex-col items-center border-2 border-double border-slate-400 px-3 pb-5"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp centre_single_tile(tile), do: SparseGrid.align(tile, :centre, {0, 0}, {3, 3})

  defp box_default_styles,
    do:
      "m-1 h-fit w-fit rounded-md border-2 border-solid border-slate-700 bg-orange-100 text-center"

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
