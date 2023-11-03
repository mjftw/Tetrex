defmodule CarsCommercePuzzleAdventure.Versioce.PostHooks.GitCommitUpdate do
  use Versioce.PostHook

  def run(version) do
    result =
      with {_, 0} <- System.cmd("git", ["add", "mix.exs", "README.md"]),
           {_, 0} <- System.cmd("git", ["commit", "-m", "Updated version to v#{version}"]) do
        :ok
      end

    case result do
      :ok -> {:ok, version}
      {error, _} -> {:error, "Git error: #{error}"}
    end
  end
end
