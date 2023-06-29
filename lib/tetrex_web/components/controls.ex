defmodule TetrexWeb.Components.Controls do
  use TetrexWeb, :html

  attr :class, :string, default: nil

  def controls(assigns) do
    ~H"""
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
  attr :label, :string, default: nil
  slot :icon, required: true
  attr :key_width, :integer, default: 1

  def key(assigns) do
    ~H"""
    <div class={[
      "rounded-md shadow-lg p-4 drop-shadow-lg ring-1 bg-slate-100 hover:translate-y-0.5  hover:drop-shadow-sm transition-all ring-slate-700  flex flex-col justify-center  items-center",
      @class
    ]}>
      <div>
        <%= render_slot(@icon) %>
      </div>
      <div>
        <span><%= @label %></span>
      </div>
    </div>
    """
  end
end
