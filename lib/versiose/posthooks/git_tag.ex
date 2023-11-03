defmodule CarsCommercePuzzleAdventure.Versioce.PostHooks.GitTag do
  use Versioce.PostHook

  def run(version) do
    case System.cmd("git", ["tag", "v#{version}"]) do
      {_, 0} -> {:ok, version}
      {error, _} -> {:error, "Git error: #{error}"}
    end
  end
end
