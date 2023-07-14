defmodule TetrexWeb.Components.Client.Audio do
  alias TetrexWeb.Components.Soundtrack

  use TetrexWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket |> assign(muted: false)}
  end

  attr :muted, :boolean, required: true
  attr :id, :string, required: true
  attr :class, :string, default: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <Soundtrack.background id={theme_music_audio_id()} src={theme_music_audio_src()} />
      <Soundtrack.effect id={game_over_audio_id()} src={game_over_audio_src()} />

      <div phx-click="toggle-muted" phx-target={@myself}>
        <%= if @muted do %>
          <svg class="hero-speaker-x-mark" />
        <% else %>
          <svg class="hero-speaker-wave" />
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle-muted", _, socket) do
    socket =
      if socket.assigns.muted do
        socket
        |> assign(:muted, false)
        |> push_event("unmute-audio", %{id: theme_music_audio_id()})
        |> push_event("unmute-audio", %{id: game_over_audio_id()})
      else
        socket
        |> assign(:muted, true)
        |> push_event("mute-audio", %{id: theme_music_audio_id()})
        |> push_event("mute-audio", %{id: game_over_audio_id()})
      end

    {:noreply, socket}
  end

  def play_game_over_audio(socket),
    do:
      socket
      |> push_event("stop-audio", %{id: theme_music_audio_id()})
      |> push_event("play-audio", %{id: game_over_audio_id()})

  def play_theme_audio(socket),
    do:
      socket
      |> push_event("stop-audio", %{id: game_over_audio_id()})
      |> push_event("play-audio", %{id: theme_music_audio_id()})

  def pause_theme_audio(socket),
    do:
      socket
      |> push_event("pause-audio", %{id: theme_music_audio_id()})

  defp theme_music_audio_src, do: "audio/tetris-main-theme.mp3"
  defp theme_music_audio_id, do: "theme-music-audio"
  defp game_over_audio_src, do: "audio/game-over.mp3"
  defp game_over_audio_id, do: "game-over-audio"
end
