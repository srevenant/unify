defmodule Mix.Tasks.Rivet.Mig do
  use Mix.Task
  import Transmogrify
  import Rivet.Mix.Common
  import String, only: [slice: 2]
  require Logger

  # "Manage Rivet migrations"
  @shortdoc "list|ls|new|pending|commit|rollback [...args]"

  @switches [
    # migration_dir: [:string, :keep],
    # migration_prefix: [:integer, :keep]
  ]

  @impl true
  def run(["help"]), do: syntax()

  def run(args) do
    case OptionParser.parse(args, strict: @switches) do
      {opts, ["new", name, label], []} -> new_migration(opts, name, label)
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

  defp module_base(name) do
    case String.split("#{name}", ".") do
      list -> List.last(list)
    end
  end

  defp new_migration(opts, name, label),
    do: Rivet.Mix.Migration.add_migration(name, label, opts)

  defp list_migrations(opts) do
    # option_configs(opts)

    case Rivet.Mix.Migration.migrations() do
      {:ok, migs} ->
        migs =
          Enum.map(migs, fn mig ->
            Map.merge(mig, %{
              model: module_base(mig.model),
              module: module_base(mig.module),
              path: "lib/#{pathname(mig.module)}.exs"
            })
          end)

        model_x = maxlen_in(migs, & &1.model)
        module_x = maxlen_in(migs, & &1.module)

        IO.puts(
          "#{pad("PREFIX", 7, " ")} #{pad("VERSION", 14, " ")} #{pad("MODEL", model_x, " ")}  #{pad("MIGRATION", module_x, " ")} -> PATH"
        )

        Enum.each(migs, fn mig ->
          indent = if mig[:base] == true, do: "** ", else: "   "
          index = pad(mig.index, 18)
          pre = slice(index, 0..3)
          ver = slice(index, 4..-1)

          IO.puts(
            "#{indent}#{pre} #{ver} #{pad(mig.model, model_x, " ")}  #{pad(mig.module, module_x, " ")} -> #{mig.path}"
          )
        end)

      {:error, msg} ->
        IO.puts(:stderr, msg)
    end
  end

  ################################################################################
  def summary(), do: "list|ls|new|pending|commit|rollback [...args]"

  def syntax(err \\ false) do
    cmd = Rivet.Mix.Common.task_cmd(__MODULE__)

    IO.puts(:stderr, """
    Syntax:

       mix.#{cmd} list|ls [-a]
       mix.#{cmd} new {ModelName} {MigrationName}
       mix.#{cmd} import {library}
       mix.#{cmd} pending
       mix.#{cmd} commit
       mix.#{cmd} rollback

    list     — List migrations
    new      — Create a new migration boilerplate and add it to indexes
    pending  — show all unapplied migrations
    commit   — commit all unapplied migrations
    rollback — undo a migration
    import   — import migrations from an third-party library

    Options:

      -a — when listing migrations, include archived migrations as well

    """)

    if err do
      IO.puts(:stderr, err)
    end
  end
end
