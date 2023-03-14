defmodule Rivet.Migration.Load do
  require Logger
  import Rivet.Migration
  import Rivet.Utils.Types, only: [as_int!: 1]
  import Transmogrify
  use Rivet

  def load_project_migrations(opts, config) do
    with {:ok, cfg, opts} <- option_configs(opts, config),
         {:ok, migs} <- migrations(cfg, opts) do
      {:ok,
       Enum.map(migs, fn %{module: mod, index: ver, path: path} ->
         Code.require_file(path)

         if Code.ensure_loaded?(mod) and function_exported?(mod, :__migration__, 0) do
           {ver, mod}
         else
           raise Ecto.MigrationError, "Module #{mod} in #{path} does not define an Ecto.Migration"
         end
       end)}
    end
  end

  def migrations(cfg, opts \\ []) do
    if not File.exists?(@migrations_file) do
      {:error, "Migrations file is missing (#{@migrations_file})"}
    else
      with {:ok, migs} <- load_data_file(@migrations_file),
           {:ok, migs} <- load_migrations({%{}, %{}}, migs, %{cfg: cfg, opts: opts}) do
        {:ok, Map.keys(migs) |> Enum.sort() |> Enum.map(&migs[&1])}
      end
    end
  end

  ##############################################################################
  defp load_migrations(out, [mcfg | rest], meta) when is_list(mcfg) do
    with {:ok, out} <- load_migration(Map.new(mcfg), out, meta),
         do: load_migrations(out, rest, meta)
  end

  defp load_migrations(out, [], _), do: {:ok, out}

  # # # # #
  defp load_migration(%{include: modref} = mcfg, out, %{cfg: %{modpath: moddir} = cfg, opts: opts}) do
    model = migration_model(modref)

    path = Path.join(Path.split(moddir) ++ [Transmogrify.pathname(model), "migrations"])

    mcfg = Map.merge(mcfg, %{model: model, opts: opts, cfg: cfg, path: path})

    {:ok, out}
    |> flatten_migrations(mcfg, path, @index_file, true)
    |> flatten_migrations(mcfg, path, @archive_file, opts[:archive])
  end

  defp load_migration(%{external: _} = ext, _out, _cfg) do
    extmix = module_extend(ext.external, "MixProject")

    if Code.ensure_loaded?(extmix) and function_exported?(extmix, :project, 0) do
      load_project_migrations([], extmix.project())
    else
      {:error, "Unable to find project information at #{extmix}"}
    end
  end

  defp load_migration(mcfg, _, _),
    do: {:error, "Invalid migration (no include or external key): #{inspect(mcfg)}"}

  ##############################################################################
  defp flatten_migrations(pass, _, _, _, false), do: pass

  defp flatten_migrations({:ok, out}, cfg, path, file, _) do
    with {:ok, includes} <- load_data_file(Path.join([path, file])),
         do: flatten_include(out, includes, cfg)
  end

  defp flatten_migrations(pass, _, _, _, _), do: pass

  # # # # #
  defp flatten_include(out, [mig | rest], cfg) do
    with {:ok, %{index: ver, module: mod} = mig} <- flatten_migration(cfg, Map.new(mig)) do
      if Map.has_key?(idx, ver) or Map.has_key?(mods, mod) do
        IO.puts(:stderr, "Ignoring duplicate migration: #{inspect(Map.to_list(mig))}")
        out
      else
        {Map.put(idx, ver, mig), Map.put(mods, mod, [])}
      end
      |> flatten_include(rest, cfg)
    end
  end

  defp flatten_include(out, [], _), do: {:ok, out}

  # # # # #
  defp flatten_migration(cfg, %{version: v, module: m} = mig) do
    with {:ok, index} <- format_index(cfg.prefix, v) do
      {:ok,
       Map.merge(mig, %{
         index: index,
         prefix: cfg.prefix,
         parent: cfg.include,
         model: cfg.model,
         module: module_extend(cfg.include, m),
         path: "#{cfg.path}/#{pathname(m)}.exs"
       })}
    end
  end

  defp format_index(prefix, v) when prefix <= 9999 and v <= 99_999_999_999_999,
    do: {:ok, as_int!(pad("#{prefix}", 4, "0") <> pad("#{v}", 14, "0"))}

  defp format_index(p, v), do: {:error, "Prefix '#{p}' or version '#{v}' out of bounds"}
end
