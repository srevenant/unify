defmodule Mix.Tasks.Rivet.Init do
  use Mix.Task
  use Rivet
  alias Rivet.Cli.Templates
  import Mix.Generator

  @shortdoc "Initialize a Rivets project. For full syntax try: mix rivet help"

  @moduledoc @shortdoc

  @impl true
  def run(_args) do
    create_file(@migrations_file, Templates.empty_list([]))

    IO.puts("""

    Create your first model with:

       mix rivet.new model {name}
    """)
  end
end
