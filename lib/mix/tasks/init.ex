defmodule Mix.Tasks.Rivet.Init do
  use Mix.Task
  use Rivet
  alias Rivet.Mix.Templates
  import Mix.Generator

  @shortdoc "Initialize a project for Rivets"

  @moduledoc @shortdoc

  @impl true
  def run(_args) do
    if not File.exists?(@migrations_file) do
      create_file(@migrations_file, Templates.empty_list([]))
    end
  end
end
