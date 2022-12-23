defmodule Mix.Tasks.Rivet do
  use Mix.Task

  @shortdoc "Prints Rivet help information"

  @moduledoc """
  Prints Rivet tasks and their information.

      $ mix rivet help|{cmd}

  x   rivet init
  x   rivet new model name
  x   rivet new migration project name
      rivet list model
  x   rivet list migration
      rivet import
      rivet pending
  .   rivet commit
      rivet rollback
  """
  @aliases %{
    "n" => "new",
    "ls" => "list",
    "l" => "list",
    "c" => "commit"
  }

  @impl true
  def run(args) do
    case args do
      [] ->
        list_commands()

      ["help"] ->
        list_commands()

      [cmd | args] ->
        cmd =
          case @aliases[cmd] do
            nil -> cmd
            cmd -> cmd
          end

        try do
          Module.safe_concat(__MODULE__, Macro.camelize(cmd)).run(args)
        rescue
          _ in ArgumentError ->
            list_commands()
            IO.puts(:stderr, "\nRivet command not found: `#{cmd}`\n")
        end
    end
  end

  defp get_full(cmd) do
  end

  defp list_commands() do
    Application.ensure_all_started(:rivet)
    Mix.shell().info("Rivet v#{Application.spec(:rivet, :vsn)}")
    Mix.shell().info("A toolkit for managing models in Elixir, working with Ecto.")
    Mix.shell().info("\nAvailable tasks:\n")
    Mix.Tasks.Help.run(["--search", "rivet."])
  end
end
