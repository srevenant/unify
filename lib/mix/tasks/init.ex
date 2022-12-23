defmodule Mix.Tasks.Rivet.Init do
  use Mix.Task
  use Rivet
  alias Rivet.Mix.Templates
  import Mix.Generator

  @shortdoc "Initialize a project for Rivets"

  @moduledoc @shortdoc

  @impl true
  def run(_args) do
    create_file(@migrations_file, Templates.empty_list([]))

    IO.puts("""

    Create your first model with:

       mix rivet model {name}
    """)
  end
end
