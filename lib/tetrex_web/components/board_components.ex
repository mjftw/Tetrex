defmodule CarsCommerceTetrisWeb.Components.BoardComponents do
  use CarsCommerceTetrisWeb, :html
  alias CarsCommerceTetris.SparseGrid

  @doc """
  Board component. Assumes board size is 10x20.
  Have to hard code this rather than passing as attrs as Tailwind CSS
  cannot handle dynamic classes due to JIT compilation.
  This means you cannot do "grid-cols-# {num_cols}".
  """
  attr(:sparsegrid, :map, required: true)

  def board(assigns) do
    ~H"""
    <svg class="h-full w-full" viewBox="0 0 1000 2000">
      <%= for y <- 0..19, x <- 0..9 do %>
        <.tile x={x} y={y} size={100} type={SparseGrid.get(@sparsegrid, y, x)} />
      <% end %>
    </svg>
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
    <svg class="h-full w-full" viewBox="0 0 400 400">
      s
      <%= for y <- 0..3, x <- 0..3 do %>
        <.tile x={x} y={y} size={100} type={SparseGrid.get(sparsegrid, y, x)} />
      <% end %>
    </svg>
    """
  end

  attr(:title, :string, required: true)
  attr(:sparsegrid, :map, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def single_tile_box(assigns) do
    ~H"""
    <div class={["#{box_default_styles()} p-2", @class]} {@rest}>
      <%= @title %> <.single_tile sparsegrid={@sparsegrid} />
    </div>
    """
  end

  attr(:board, :map, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def next_tile_box(assigns) do
    ~H"""
    <.single_tile_box title="Next" sparsegrid={@board.next_tile} class={@class} {@rest} />
    """
  end

  attr(:board, :map, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def hold_tile_box(assigns) do
    ~H"""
    <.single_tile_box title="Hold" sparsegrid={@board.hold_tile} class={@class} {@rest} />
    """
  end

  attr(:board, :map, required: true)
  attr(:is_dead, :boolean, required: false, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def playfield(assigns) do
    ~H"""
    <div class={[box_default_styles(), if(@is_dead, do: "bg-slate-400", else: ""), @class]} {@rest}>
      <.board sparsegrid={@board.playfield} />
    </div>
    """
  end

  attr(:score, :integer, required: true)
  attr(:class, :string, default: nil)

  def score_box(assigns) do
    ~H"""
    <div class={[box_default_styles(), "p-2 text-xl", @class]}>
      Score: <%= @score %>
    </div>
    """
  end

  attr(:player_states, :list, required: true)

  def multiplayer_tiled_playfields(assigns) do
    ~H"""
    <% grid_props = fn ->
      num_players = Enum.count(@player_states)

      cond do
        num_players == 1 -> "grid-cols-1 w-2/3"
        num_players <= 6 -> "grid-cols-2"
        num_players <= 9 -> "grid-cols-3"
        num_players <= 16 -> "grid-cols-4"
        num_players <= 25 -> "grid-cols-5"
        num_players <= 36 -> "grid-cols-6"
        num_players <= 49 -> "grid-cols-7"
        true -> "grid-cols-8"
      end
    end %>

    <div class="flex h-full items-center justify-end rounded-md bg-neutral-200 px-2">
      <div class={["grid grid-flow-dense", grid_props.()]}>
        <%= for {_user_id, %{board_preview: board_preview, status: status}} <- @player_states do %>
          <.playfield board={board_preview} is_dead={status == :dead} />
        <% end %>
      </div>
    </div>
    """
  end

  defp centre_single_tile(tile), do: SparseGrid.align(tile, :centre, {0, 0}, {3, 3})

  defp box_default_styles,
    do:
      "m-1 h-fit w-fit rounded-md border-2 border-solid border-slate-700 bg-orange-100 text-center"

  attr(:type, :atom, required: true)
  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:size, :integer, required: true)
  attr(:rest, :global)

  defp tile(%{type: :red} = assigns) do
    ~H"""
    <.tile_filled x={@x} y={@y} size={@size} class="fill-red-400" />
    """
  end

  defp tile(%{type: :green} = assigns) do
    ~H"""
    <.tile_filled x={@x} y={@y} size={@size} class="fill-green-400" />
    """
  end

  defp tile(%{type: :blue} = assigns) do
    ~H"""
    <.tile_filled x={@x} y={@y} size={@size} class="fill-blue-400" />
    """
  end

  defp tile(%{type: :cyan} = assigns) do
    ~H"""
    <.tile_filled x={@x} y={@y} size={@size} class="fill-cyan-400" />
    """
  end

  defp tile(%{type: :yellow} = assigns) do
    ~H"""
    <.tile_filled x={@x} y={@y} size={@size} class="fill-yellow-400" />
    """
  end

  defp tile(%{type: :purple} = assigns) do
    ~H"""
    <.tile_filled x={@x} y={@y} size={@size} class="fill-purple-400" />
    """
  end

  defp tile(%{type: :orange} = assigns) do
    ~H"""
    <.tile_filled x={@x} y={@y} size={@size} class="fill-orange-400" />
    """
  end

  defp tile(%{type: :drop_preview} = assigns) do
    ~H"""
    <.tile_edged x={@x} y={@y} size={@size} class="fill-slate-500 stroke-0" fill-opacity="0.15" />
    """
  end

  defp tile(%{type: :blocking} = assigns) do
    ~H"""
    <.tile_edged x={@x} y={@y} size={@size} class="fill-slate-700 stroke-slate-800" />
    """
  end

  defp tile(%{type: nil} = assigns) do
    ~H"""

    """
  end

  attr(:class, :string, default: nil)
  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:size, :integer, required: true)
  attr(:rest, :global)

  @doc """
  A square SVG that is slightly overlapping the viewBox on all sides to give a filled box
  """
  defp tile_filled(assigns) do
    ~H"""
    <rect
      x={@x * @size}
      y={@y * @size}
      width={@size}
      height={@size}
      class={["stroke-none", @class]}
      {@rest}
    />
    """
  end

  attr(:class, :string, default: nil)
  attr(:x, :integer, required: true)
  attr(:y, :integer, required: true)
  attr(:size, :integer, required: true)
  attr(:border_width, :integer, default: 2)
  attr(:rest, :global)

  @doc """
  A square SVG that is slightly within the viewBox to give a border stroke
  """
  defp tile_edged(assigns) do
    ~H"""
    <rect
      x={@x * @size + @border_width}
      y={@y * @size + @border_width}
      width={@size - 2 * @border_width}
      height={@size - 2 * @border_width}
      class={["stroke-2", @class]}
      {@rest}
    />
    """
  end
end
