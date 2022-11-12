defmodule Mix.Tasks.Rivet.Mig do
  use Mix.Task
  import Mix.Generator
  import Transmogrify
  import Rivet.Mix.Common
  require Logger

  @moduledoc """
  Manage Ecto migrations
  """

  @switches [
    migration_dir: [:string, :keep],
    migration_prefix: [:integer, :keep]
  ]

  def run(args) do
    case OptionParser.parse(args, strict: @switches) do
      {opts, ["new", name], []} -> new_migration(opts, name)
      {opts, ["list"], []} -> list_migrations(opts)
      {opts, ["ls"], []} -> list_migrations(opts)
      {_, ["import"], _} -> syntax("no applications listed")
      {opts, ["import" | rest], []} -> import_migrations(opts, rest)
      {_, _, []} -> syntax()
      {_, _, errs} -> syntax(inspect(errs, label: "bad arguments"))
    end
  end

  defp import_migrations(opts, apps) do
    IO.inspect({opts, apps})
  end

  defp get_list(opts) do
    conf = %{migdir: migdir} = option_configs(opts)
    opts = Keyword.merge([migdir: migdir], opts)
    {conf, opts, Rivet.Mix.Migration.list_migrations(opts[:migdir])}
  end

  defp new_migration(opts, name) do
    %{migdir: migdir, base: base} = option_configs(opts)
    {:ok, next} = Rivet.Mix.Migration.format_migration_index()

    opts = [
      c_name: modulename(name),
      c_base: base,
      c_index: next
    ]

    name = pathname(name)

    create_file("#{migdir}#{next}_#{name}.exs", migration_template(opts))
  end

  defp list_migrations(opts) do
    with {_, opts, %{migrations: m, schemas: s}} <- get_list(opts) do
      migdir = opts[:migdir]

      Map.keys(s)
      |> Enum.sort()
      |> Enum.each(fn prefix ->
        IO.puts("\n-- SCHEMA prefix=#{prefix}")
        max = maxlen_in(Enum.map(s[prefix], fn {_, %{label: l}} -> l end))

        Enum.each(s[prefix], fn {index, vals} ->
          joined = Path.join(nodot(migdir) ++ ["#{index}_BASE_#{vals.label}.exs"])
          IO.puts("   #{index} #{String.pad_trailing(vals.label, max)} - #{joined}")
        end)
      end)

      maxl = maxlen_in(Map.values(m))
      maxi = maxlen_in(Map.keys(m))
      IO.puts("\n-- MIGRATIONS")

      Map.keys(m)
      |> Enum.sort()
      |> Enum.each(fn index ->
        joined = Path.join(nodot(migdir) ++ ["#{index}_#{m[index]}.exs"])

        IO.puts(
          "   #{String.pad_trailing(index, maxi)} #{String.pad_trailing(m[index], maxl)} - #{joined}"
        )
      end)
    end
  end

  defp maxlen_in(list), do: Enum.reduce(list, 0, fn i, x -> max(String.length(i), x) end)

  ################################################################################
  defp syntax(err \\ false) do
    cmd = Rivet.Mix.Common.task_cmd(__MODULE__)

    IO.puts(:stderr, """
    Syntax:
       mix #{cmd} list|ls
       mix #{cmd} new {name}
       mix #{cmd} import {app1} [app2, ...]

    TODO: list options here
    """)

    if err do
      IO.puts(:stderr, err)
    end
  end

  embed_template(:migration, """
  defmodule <%= @c_base %>.Migrations.<%= @c_name %><%= @c_index %> do
    @moduledoc false
    use Ecto.Migration

    def change do

    end
  end
  """)
end
