# AGENT.md - Tetrex Development Guide

## Commands
- **Server**: `mix phx.server` (dev server at http://localhost:4000)
- **Setup**: `mix setup` (install deps, setup assets)
- **Test**: `mix test` (run all tests)
- **Test single file**: `mix test test/tetrex/tetromino_test.exs`
- **Lint**: `mix credo` (code quality checks)
- **Format**: `mix format` (auto-format code)
- **Build**: `mix compile`
- **Version bump**: `mix bump patch|minor|major`
- **Deploy**: `fly deploy`

## Architecture
- **Phoenix LiveView app** with real-time multiplayer Tetris
- **OTP processes**: `BoardServer` for game state, `GameDynamicSupervisor` for game lifecycle
- **Core modules**: `Tetrex.Board`, `Tetrex.Tetromino`, `Tetrex.SparseGrid`
- **Web layer**: Phoenix LiveView components in `TetrexWeb.Live.*`
- **Persistence**: Game state auto-saved, no database required
- **Multiplayer**: Phoenix channels and presence for real-time sync

## Code Style
- **Imports**: Use `alias` for modules, avoid `import` unless necessary
- **Naming**: snake_case for functions/variables, PascalCase for modules
- **Line length**: 120 characters max (configured in Credo)
- **Formatting**: TailwindFormatter for .heex files, standard Elixir formatter
- **Documentation**: `@moduledoc` and `@doc` for public functions
- **Types**: Use `@type` specifications for clarity
- **Error handling**: Use `{:ok, result}` / `{:error, reason}` tuples
