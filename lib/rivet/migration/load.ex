defmodule Rivet.Migration.Load do
  require Logger
  import Rivet.Migration
  import Rivet.Utils.Types, only: [as_int!: 1]
  import Transmogrify
  use Rivet

  @doc """
  External interface to get migrations ready for use by Ecto
  """
  def prepare_project_migrations(opts, project_config) do
    with {:ok, config} <- Rivet.Config.build(opts, project_config),
         {:ok, migs} <- load_project_migrations(config) do
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

  ##############################################################################
  defp load_project_migrations(config) do
    if not File.exists?(@migrations_file) do
      {:error, "Migrations file is missing (#{@migrations_file})"}
    else
      with {:ok, migs} <- load_data_file(@migrations_file),
           {:ok, migs} <-
             load_project_migrations(%{idx: %{}, mods: %{}}, migs, config) do
        {:ok, Map.keys(migs) |> Enum.sort() |> Enum.map(&migs[&1])}
      end
    end
  end

  defp load_project_migrations(state, [model_migration | rest], config)
       when is_list(model_migration) do
    with {:ok, state} <- load_project_migration(Map.new(model_migration), state, config),
         do: load_project_migrations(state, rest, config)
  end

  defp load_project_migrations(state, [], _), do: {:ok, state}

  # # # # #
  defp load_project_migration(%{include: _} = model_migration, state, %{opts: opts} = config) do
    with {:ok, model_migration} <- prepare_model_config(model_migration, config) do
      {:ok, state}
      |> merge_model_migrations(model_migration, @index_file, true)
      |> merge_model_migrations(model_migration, @archive_file, opts[:archive] == true)
    end
  end

  defp load_project_migration(%{external: _} = model_migration, _state, _cfg) do
    extmix = module_extend(model_migration.external, "MixProject")

    if Code.ensure_loaded?(extmix) and function_exported?(extmix, :project, 0) do
      with {:ok, config} <-
             Rivet.Config.build(
               [
                 base: "../../deps/asdfasdfa"
               ],
               extmix.project()
             ),
           do: load_project_migrations(config)
    else
      {:error, "Unable to find project information at #{extmix}"}
    end
  end

  defp load_project_migration(model_migration, _, _),
    do: {:error, "Invalid migration (no include or external key): #{inspect(model_migration)}"}

  ##############################################################################
  def prepare_model_config(%{include: modref} = model_migration, %{models_root: root}) do
    model = migration_model(modref)
    path = Path.join(Path.split(root) ++ [Transmogrify.pathname(model), "migrations"])
    {:ok, Map.merge(model_migration, %{model: model, path: path})}
  end

  ##############################################################################
  def merge_model_migrations(pass, _, _, false), do: pass

  def merge_model_migrations({:ok, state}, cfg, file, _) do
    with {:ok, includes} <- load_data_file(Path.join([cfg.path, file])),
         do: flatten_include(state, includes, cfg)
  end

  def merge_model_migrations(pass, _, _, _), do: pass

  # # # # #
  defp flatten_include(state, [mig | rest], cfg) do
    with {:ok, %{index: ver, module: mod} = mig} <- flatten_migration(cfg, Map.new(mig)) do
      if Map.has_key?(state.idx, ver) or Map.has_key?(state.mods, mod) do
        IO.puts(:stderr, "Ignoring duplicate migration: #{inspect(Map.to_list(mig))}")
        state
      else
        %{state | idx: Map.put(state.idx, ver, mig), mods: Map.put(state.mods, mod, [])}
      end
      |> flatten_include(rest, cfg)
    end
  end

  defp flatten_include(state, [], _), do: {:ok, state}

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
