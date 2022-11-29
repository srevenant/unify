defmodule Mix.Tasks.Rivet do
  @moduledoc """
  Because it's more idiomatic (outside of elixir) to have spaces, not dots
  """

  use Mix.Task
  require Logger

  # todo: Make a python-like self-describing arg system that supports sub-commands
  def run(["help" | _]), do: list_commands()

  def run([cmd | args]) do
    Module.safe_concat(__MODULE__, Macro.camelize(cmd)).run(args)
  rescue
    _ in ArgumentError ->
      list_commands()
      IO.puts(:stderr, "\nRivet command not found: `#{cmd}`\n")
  end

  def run([]), do: list_commands()

  defp list_commands() do
    cmd = Rivet.Mix.Common.task_cmd(__MODULE__)
    IO.puts(:stderr, "\nSyntax:\n")

    with {:ok, mods} <- :application.get_key(:rivet, :modules) do
      Enum.each(mods, fn mod ->
        case "#{mod}" do
          "Elixir.Mix.Tasks.Rivet." <> sub ->
            IO.puts(:stderr, "  mix #{cmd} #{Macro.underscore(sub)} #{mod.summary()}")

          _ ->
            :ok
        end
      end)
    end
  end
end
