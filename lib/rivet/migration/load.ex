defmodule Rivet.Migration.Load do
  require Logger
  import Rivet.Migration
  import Rivet.Utils.Types, only: [as_int!: 1]
  import Transmogrify
  use Rivet

  @initial_state %{idx: %{}, mods: %{}}

  defp module_loaded?(mod, file) do
    if Code.ensure_loaded?(mod) do
      true
    else
      Code.require_file(file)
      true
    end
  rescue
    _ ->
      false
  end

  @doc """
  External interface to get migrations ready for use by Ecto
  """
  # @spec prepare_project_migrations(opts :: list(), project_config :: list()) ::
  #         {:ok, rivet_migrations()} | rivet_error()
  def prepare_project_migrations(opts, project_config) do
    with {:ok, config} <- Rivet.Config.build(opts, project_config),
         {:ok, migs} <- load_migrations_from_config(config) do
      {:ok,
       Enum.map(migs, fn %{module: mod, index: ver, path: path} ->
         if module_loaded?(mod, path) and function_exported?(mod, :__migration__, 0) do
           {ver, mod}
         else
           raise Ecto.MigrationError, "Module #{mod} in #{path} does not define an Ecto.Migration"
         end
       end)}
    end
  end

  ##############################################################################
  # @spec load_project_migrations(rivet_config()) :: {:ok, rivet_migrations()} | rivet_error()
  defp load_migrations_from_config(rivet_config) do
    migfile = Path.join(rivet_config.base_path, @migrations_file)

    if not File.exists?(migfile) do
      {:error, "Migrations file is missing (#{migfile})"}
    else
      with {:ok, mig_data} <- load_data_file(migfile),
           do: load_project_migrations(@initial_state, mig_data, rivet_config)
    end
  end

  defp state_to_list(%{idx: idx}), do: {:ok, Map.keys(idx) |> Enum.sort() |> Enum.map(&idx[&1])}

  # @spec load_project_migrations(
  #         rivet_migration_state(),
  #         list(rivet_migration_input_include() | rivet_migration_input_external()),
  #         rivet_config()
  #       ) ::
  #         rivet_state_result()
  defp load_project_migrations(state, [model_migration | rest], config)
       when is_list(model_migration) and is_map(state) do
    with {:ok, state} <-
           load_project_migration(Map.new(model_migration), state, config),
         do: load_project_migrations(state, rest, config)
  end

  defp load_project_migrations(%{idx: _, mods: _} = state, [], _), do: {:ok, state}

  defp load_project_migrations({:error, _} = pass, _, _), do: pass

  ##############################################################################
  # @spec load_project_migration(
  #         rivet_migration_input_include() | rivet_migration_input_external(),
  #         rivet_migration_state(),
  #         rivet_config()
  #       ) ::
  #         rivet_state_result()
  defp load_project_migration(
         %{include: _} = model_migration,
         state,
         %{opts: opts} = rivet_config
       ) do
    with {:ok, model_mig} <- prepare_model_config(model_migration, rivet_config) do
      {:ok, state}
      |> merge_model_migrations(model_mig, @index_file, true)
      |> merge_model_migrations(model_mig, @archive_file, opts[:archive] == true)
    end
  end

  defp load_project_migration(%{external: extmod} = model_migration, state, cfg) do
    extmix = module_extend(extmod, "MixProject")
    path = Path.join(cfg[:deps_path], Transmogrify.Pathname.convert(extmod))

    if module_loaded?(extmix, Path.join(path, "mix.exs")) and
         function_exported?(extmix, :project, 0) do
      with {:ok, config} <- Rivet.Config.build([base_dir: path], extmix.project()),
           do: load_project_migrations(state, model_migration.migrations, config)
    else
      {:error, "Unable to find project information at #{extmix}"}
    end
  end

  defp load_project_migration(model_migration, _, _),
    do: {:error, "Invalid migration (no include or external key): #{inspect(model_migration)}"}

  ##############################################################################
  # @spec prepare_model_config(rivet_migration_input_any(), rivet_config()) :: {:ok, Rivet.Migration.t()} | rivet_error()
  def prepare_model_config(%{include: modref} = model_migration, %{models_root: root}) do
    model = migration_model(modref)
    path = Path.join(Path.split(root) ++ [Transmogrify.pathname(model), "migrations"])
    {:ok, %Rivet.Migration{struct(Rivet.Migration, model_migration) | model: model, path: path}}
  end

  ##############################################################################
  # @spec merge_model_migrations(
  #         rivet_error() | {:ok, rivet_migration_state()},
  #         rivet_config(),
  #         String.t(),
  #         boolean()
  #       ) ::
  #         rivet_state_result()
  def merge_model_migrations({:ok, _} = pass, _, _, false), do: pass

  def merge_model_migrations({:ok, state}, rivet_config, file, _) do
    with {:ok, includes} <- load_data_file(Path.join([rivet_config.path, file])),
         do: flatten_include(state, includes, rivet_config)
  end

  def merge_model_migrations({:error, _} = pass, _, _, _), do: pass

  # # # # #
  # @spec flatten_include(rivet_migration_state(), list(map()), rivet_config()) ::
  #         rivet_state_result()
  defp flatten_include(state, [mig | rest], r_cfg) do
    with {:ok, %{index: ver, module: mod} = mig} <- flatten_migration(r_cfg, Map.new(mig)) do
      if Map.has_key?(state.idx, ver) or Map.has_key?(state.mods, mod) do
        IO.puts(:stderr, "Ignoring duplicate migration: #{inspect(Map.to_list(mig))}")
        state
      else
        %{state | idx: Map.put(state.idx, ver, mig), mods: Map.put(state.mods, mod, [])}
      end
      |> flatten_include(rest, r_cfg)
    end
  end

  defp flatten_include(state, [], _) when is_map(state), do: {:ok, state}

  # # # # #
  # @spec flatten_migration(map(), rivet_migration_input_model()) ::
  #         {:ok, Rivet.Migration.t()} | rivet_error()
  defp flatten_migration(
         %Rivet.Migration{prefix: prefix, include: include, model: model, path: path},
         %{
           version: ver,
           module: module
         } = mig
       ) do
    with {:ok, index} <- format_index(prefix, ver) do
      {:ok,
       %Rivet.Migration{
         base: Map.get(mig, :base, false),
         version: ver,
         index: index,
         prefix: prefix,
         parent: include,
         model: model,
         module: module_extend(include, module),
         path: "#{path}/#{pathname(module)}.exs"
       }}
    end
  end

  # @spec format_index(integer(), integer()) :: {:ok | :error, String.t()}
  defp format_index(prefix, v) when prefix <= 9999 and v <= 99_999_999_999_999,
    do: {:ok, as_int!(pad("#{prefix}", 4, "0") <> pad("#{v}", 14, "0"))}

  defp format_index(p, v), do: {:error, "Prefix '#{p}' or version '#{v}' out of bounds"}
end
