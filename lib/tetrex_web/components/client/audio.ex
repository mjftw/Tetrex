defmodule TetrexWeb.Components.Client.Audio do
  alias TetrexWeb.Components.Soundtrack
  use TetrexWeb, :live_component

  def tetris_audio(assigns) do
    ~H"""
    <Soundtrack.background id={theme_music_audio_id()} src={theme_music_audio_src()} loop />
    <Soundtrack.effect id={game_over_audio_id()} src={game_over_audio_src()} />
    """
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
