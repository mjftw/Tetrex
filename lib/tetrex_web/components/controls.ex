defmodule CarsCommercePuzzleAdventureWeb.Components.Controls do
  use CarsCommercePuzzleAdventureWeb, :html

  attr :class, :string, default: nil

  def controls(assigns) do
    ~H"""
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
    />
    <div class={["grid grid-cols-7 gap-3 aspect-[5/4]", @class]}>
      <.key label="hold" class="col-span-2 col-start-1 row-span-2 row-start-1">
        <:icon><span class="text-xl">h</span></:icon>
      </.key>
      <.key label="rotate" class="col-span-2 col-start-4 row-span-2 row-start-2">
        <:icon><svg class="hero-arrow-up-mini" /></:icon>
      </.key>
      <.key label="left" class="col-span-2 col-start-2 row-span-2 row-start-4">
        <:icon><svg class="hero-arrow-left-mini" /></:icon>
      </.key>
      <.key label="down" class="col-span-2 row-span-2 row-start-4">
        <:icon><svg class="hero-arrow-down-mini" /></:icon>
      </.key>
      <.key label="right" class="col-span-2 row-span-2 row-start-4">
        <:icon><svg class="hero-arrow-right-mini" /></:icon>
      </.key>
      <.key label="drop" key_width={3} class="row-start- col-span-6 col-start-2 row-span-1">
        <:icon><svg class="hero-minus" /></:icon>
      </.key>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :on_hold, JS, default: %JS{}
  attr :on_left, JS, default: %JS{}
  attr :on_right, JS, default: %JS{}
  attr :on_rotate, JS, default: %JS{}
  attr :on_down, JS, default: %JS{}
  attr :on_drop, JS, default: %JS{}

  def mobile_controls(assigns) do
    ~H"""
    <div class={["flex flex-row justify-between", @class]}>
      <div class="grid grid-cols-3 gap-1">
        <.key
          label="drop"
          key_width={1}
          class="col-span-3 col-start-1 row-span-2 row-start-1"
          phx-click={@on_drop}
        >
          <:icon><svg class="hero-chevron-double-down" /></:icon>
        </.key>
        <.key label="hold" class="col-span-3 col-start-1 row-span-2 row-start-3" phx-click={@on_hold}>
          <:icon><svg class="hero-arrow-left-on-rectangle" /></:icon>
        </.key>
      </div>
      <div class="grid grid-cols-7 gap-1">
        <.key
          label="rotate"
          class="col-span-4 col-start-4 row-span-1 row-start-2"
          phx-click={@on_rotate}
        >
          <:icon><svg class="hero-arrow-path" /></:icon>
        </.key>
        <.key label="left" class="col-span-2 col-start-4 row-span-2 row-start-4" phx-click={@on_left}>
          <:icon><svg class="hero-arrow-left-mini" /></:icon>
        </.key>
        <.key
          label="right"
          class="col-span-2 col-start-6 row-span-2 row-start-4"
          phx-click={@on_right}
        >
          <:icon><svg class="hero-arrow-right-mini" /></:icon>
        </.key>
        <.key label="down" class="col-span-4 col-start-4 row-span-1 row-start-6" phx-click={@on_down}>
          <:icon><svg class="hero-arrow-down-mini" /></:icon>
        </.key>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :label, :string, default: nil
  slot :icon, required: true
  attr :key_width, :integer, default: 1
  attr :rest, :global

  def key(assigns) do
    ~H"""
    <button
      class={[
        "rounded-md shadow-lg p-4 drop-shadow-lg ring-1 bg-slate-100 ring-slate-700 flex flex-col justify-center  items-center",
        "phx-click-loading:translate-y-0.5 phx-click-loading:drop-shadow-sm phx-click-loading:bg-slate-200 transition-all ",
        @class
      ]}
      {@rest}
    >
      <div>
        <%= render_slot(@icon) %>
      </div>
      <div>
        <span><%= @label %></span>
      </div>
    </button>
    """
  end
end
