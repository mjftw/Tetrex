defmodule CarsCommercePuzzleAdventure.Versioce.PreHooks.GitCheckUncommitted do
  use Versioce.PreHook

  def run(params) do
    case System.cmd("git", ["status", "--porcelain=v1"]) do
      {"", 0} ->
        {:ok, params}

      {files, 0} ->
        {:error,
         "Ensure no uncommitted files before bumping the version.\n\nUncommitted:\n#{files}"}

      {error, _} ->
        {:error, "Git error: #{error}"}
    end
  end
end
