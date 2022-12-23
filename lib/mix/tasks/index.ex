defmodule Mix.Tasks.Rivet do
  use Mix.Task

  @shortdoc "Prints Rivet help information"

  @moduledoc """
  Prints Rivet tasks and their information.

      $ mix rivet help|{cmd}

  """

  @impl true
  def run(args) do
    case args do
      [] ->
        list_commands()

      ["help"] ->
        list_commands()

      [cmd | args] ->
        try do
          Module.safe_concat(__MODULE__, Macro.camelize(cmd)).run(args)
        rescue
          _ in ArgumentError ->
            list_commands()
            IO.puts(:stderr, "\nRivet command not found: `#{cmd}`\n")
        end
    end
  end

  defp list_commands() do
    Application.ensure_all_started(:rivet)
    Mix.shell().info("Rivet v#{Application.spec(:rivet, :vsn)}")
    Mix.shell().info("A toolkit for managing models in Elixir, working with Ecto.")
    Mix.shell().info("\nAvailable tasks:\n")
    Mix.Tasks.Help.run(["--search", "rivet."])
  end
end
