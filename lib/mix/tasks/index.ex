defmodule Mix.Tasks.Rivet do
  use Mix.Task

  @shortdoc "Prints Rivet help information"

  @moduledoc """
  Prints Rivet tasks and their information.

      $ mix rivet

  """

  @impl true
  def run(_) do
    Application.ensure_all_started(:rivet)
    Mix.shell().info "Rivet v#{Application.spec(:rivet, :vsn)}"
    Mix.shell().info "A toolkit for managing models in Elixir, working with Ecto."
    Mix.shell().info "\nAvailable tasks:\n"
    Mix.Tasks.Help.run(["--search", "rivet."])
  end
  # @impl true
  # def run([cmd | args]) do
  #   Module.safe_concat(__MODULE__, Macro.camelize(cmd)).run(args)
  # rescue
  #   _ in ArgumentError ->
  #     list_commands()
  #     IO.puts(:stderr, "\nRivet command not found: `#{cmd}`\n")
  # end

  # def run([]), do: list_commands()
  #
  # defp list_commands() do
  #   cmd = Rivet.Mix.Common.task_cmd(__MODULE__)
  #   IO.puts(:stderr, "\nSyntax:\n")
  #
  #   IO.inspect(:application.get_key(:rivet, :modules))
  #   with {:ok, mods} <- :application.get_key(:rivet, :modules) do
  #     Enum.each(mods, fn mod ->
  #       case "#{mod}" do
  #         "Elixir.Mix.Tasks.Rivet." <> sub ->
  #           IO.puts(:stderr, "  mix #{cmd} #{Macro.underscore(sub)} #{mod.summary()}")
  #
  #         _ ->
  #           :ok
  #       end
  #     end)
  #   end
  # end
end
