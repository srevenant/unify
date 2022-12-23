defmodule Rivet.Mix.Migration do
  @moduledoc false
  require Logger
  import Rivet.Mix.Common
  import Rivet.Utils.Types, only: [as_int!: 1]
  alias Rivet.Mix.Templates
  import Mix.Generator
  import Transmogrify
  use Rivet

  # @default_step 100
  # @default_index %{schemas: %{}, migrations: %{}}
  # @version_width 14
  def add_migration(model, label, opts \\ []) do
    with {:ok, opts, _} <- option_configs(opts) do
      ver = (opts[:version] || datestamp()) |> as_int!()
      parts = module_parts(model, label, ver, opts)

      cond do
        not File.exists?(parts.path.model) ->
          {:error, "Model not found `#{parts.name.model}` in `#{parts.path.model}`"}

        not File.exists?(parts.path.migrations) ->
          {:error,
           "Model Migrations not found `#{parts.name.migrations}` in `#{parts.path.migrations}`"}

        # TODO: figure out how it'llwork so we can put version in path, and check
        # if module exists by name, without version#. Code.module_exists() doesn't
        # work with .exs files...
        File.exists?(parts.path.migration) ->
          {:error,
           "Model Migration already exists `#{parts.name.migration}` in `#{parts.path.migration}`"}

        true ->
          create_migration(parts, opts)
      end
    end
  end

  defp create_migration(parts, opts) do
    mig =
      if opts[:base] == true do
        [base: true]
      else
        []
      end ++ [module: as_module(parts.base), version: parts.ver]

    opts =
      Map.to_list(opts)
      |> Keyword.merge(
        c_base: parts.name.model,
        c_name: parts.base,
        c_index: parts.ver
      )

    create_file(parts.path.migration, Templates.migration(opts))
    index = Path.join(parts.path.migrations, ".index.exs")

    with {migs, _} <- Code.eval_file(index) do
      migs =
        [mig | migs]
        |> Enum.sort(fn a, b -> Keyword.get(a, :version) >= Keyword.get(b, :version) end)

      File.write!(index, inspect(migs, pretty: true))
    end
  end

  defp module_parts(model, label, ver, opts) do
    model_name =
      case String.split(modulename(model), ".") do
        [one] ->
          "#{opts.base}.#{one}"

        [_ | _] = mod ->
          Enum.join(mod, ".")
      end

    base = modulename(label)
    migs_name = "#{model_name}.Migrations"
    mig_name = "#{migs_name}.#{base}"

    %{
      base: base,
      ver: ver,
      name: %{
        model: model_name,
        migrations: migs_name,
        migration: mig_name
      },
      path: %{
        model: "lib/" <> pathname(model_name),
        migrations: "lib/" <> pathname(migs_name),
        migration: "lib/#{pathname(mig_name)}.exs"
      }
    }
  end

  #
  # defp add_project_migration(%{module: module}) do
  #
  #   if not File.exists?(migrations) do
  #     create_file(migrations, empty_list_template(opts))
  #   end
  #
  #   case Rivet.Mix.Migration.add_migration_include(migrations, basemod) do
  #     {:exists, prefix} ->
  #       IO.puts("""
  #
  #       Model already exists in `#{migrations}`, not adding
  #
  #       """)
  #
  #     {:ok, mig} ->
  #       IO.puts("""
  #
  #       Model added to `#{migrations}` with prefix `#{mig[:prefix]}`
  #
  #       """)
  #
  #     {:error, error} ->
  #       IO.puts(:stderr, error)
  #   end
  # end

  def migrations(opts \\ []) do
    if not File.exists?(@migrations_file) do
      {:error, "Migrations file is missing (#{@migrations_file})"}
    else
      with {:ok, migs} <- load_config_file(@migrations_file) do
        {migs, _} =
          Enum.reduce(migs, {%{}, %{}}, fn cfg, out ->
            cfg = Map.new(cfg)

            case cfg[:include] do
              nil ->
                IO.puts(:stderr, "Invalid migration (no include key), #{inspect(cfg)}")

              mod ->
                model = module_pop(mod)
                cfg = Map.put(cfg, :model, model)
                path = Path.join("lib/", Transmogrify.pathname(mod))

                out
                |> flatten_migrations(cfg, path, ".index.exs", true)
                |> flatten_migrations(cfg, path, ".archive.exs", opts[:archive])
            end
          end)

        {:ok, Map.keys(migs) |> Enum.sort() |> Enum.map(&migs[&1])}
      end
    end
  end

  defp flatten_migrations(out, _, _, _, false), do: out

  defp flatten_migrations(out, cfg, path, file, _) do
    case load_config_file(Path.join([path, file])) do
      {:ok, inc} ->
        Enum.reduce(inc, out, fn mig, {idx, mods} = acc ->
          case flatten_migration(cfg, Map.new(mig)) do
            %{index: ver, module: mod} = mig ->
              if Map.has_key?(idx, ver) or Map.has_key?(mods, mod) do
                IO.puts(:stderr, "Ignoring duplicate migration: #{inspect(Map.to_list(mig))}")
                acc
              else
                {Map.put(idx, ver, mig), Map.put(mods, mod, [])}
              end
          end
        end)
      {:error, err} ->
        IO.puts(:stderr, err)
        out
    end
  end

  defp flatten_migration(cfg, %{version: v, module: m} = mig) do
    # %{prefix: prefix, include: mod},
    Map.merge(mig, %{
      index: format_version(cfg.prefix, v),
      prefix: cfg.prefix,
      parent: cfg.include,
      model: cfg.model,
      module: module_extend(cfg.include, m)
    })
  end

  defp format_version(prefix, v) when prefix <= 9999 and v <= 99_999_999_999_999,
    do: as_int!(pad("#{prefix}", 4, "0") <> pad("#{v}", 14, "0"))

  defp format_version(_, _), do: raise("Prefix or version out of bounds")

  # def link_next_schema(schema_file, name, migdir, prefix, order) when prefix < 100 do
  #   prefix = String.pad_leading("#{prefix}", 2, "0")
  #   migrations = list_migrations(migdir)
  #
  #   schemas =
  #     case get_in(migrations, [:schemas, prefix]) do
  #       nil -> %{}
  #       val -> val
  #     end
  #
  #   next =
  #     if is_nil(order) do
  #       case migrations do
  #         %{next: %{^prefix => next}} -> format_schema_index(prefix, next)
  #         _ -> format_schema_index(prefix, 0)
  #       end
  #     else
  #       format_schema_index(prefix, order)
  #     end
  #
  #   if Map.has_key?(schemas, next) do
  #     {:error, "Cannot use index `#{next}` for schema order as it's already taken"}
  #   else
  #     backstep = nodot(migdir) |> Enum.map(fn _ -> ".." end) |> Path.join()
  #     schema = nodot(schema_file) |> Path.join()
  #
  #     File.ln_s("#{backstep}/#{schema}", "#{migdir}/#{next}_BASE_#{name}.exs")
  #   end
  # end
  #
  # def link_next_schema(_, _, _, _, _), do: {:error, "Invalid link options"}
  #
  # ##############################################################################
  # def format_schema_index(prefix, order) when order < 1_000_000_000,
  #   do: "00" <> String.pad_leading("#{prefix}", 2, "0") <> String.pad_leading("#{order}", 10, "0")
  #
  # def format_schema_index(_, order), do: raise("order (#{order}) is out of bounds")
  #
  # def format_migration_index(), do: Timex.now() |> Timex.format("{YYYY}{M}{0D}{h24}{m}{s}")
  #
  # def list_migrations(folder, step \\ @default_step) do
  #   case File.ls(folder) do
  #     {:ok, files} ->
  #       result = scan_migration_files(@default_index, files)
  #
  #       Map.put(
  #         result,
  #         :next,
  #         Enum.reduce(result.schemas, %{}, fn {prefix, schemas}, acc ->
  #           next = get_next_schema(schemas)
  #           Map.put(acc, prefix, next + step)
  #         end)
  #       )
  #
  #     _error ->
  #       {:error, "failure listing files"}
  #   end
  # end
  #
  # defp get_next_schema(schemas) do
  #   schemas
  #   |> Enum.map(fn {_, %{index: o}} -> o end)
  #   |> Enum.sort()
  #   |> Enum.reverse()
  #   |> case do
  #     [last | _] -> last
  #     _ -> 0
  #   end
  # end
  #
  # ##############################################################################
  # def scan_migration_files(acc, [fname | files]) do
  #   case Regex.run(~r/^(\d\d)(\d\d)([0-9]+)_?(BASE_)?(.*).exs$/i, fname) do
  #     nil ->
  #       Logger.debug("Ignoring unmatched migration file '#{fname}'")
  #       acc
  #
  #     [_, "00", pfix, index, "BASE_", label] ->
  #       key = "00#{pfix}#{index}"
  #       value = %{prefix: String.to_integer(pfix), index: String.to_integer(index), label: label}
  #
  #       Map.replace(
  #         acc,
  #         :schemas,
  #         Map.update(acc.schemas, pfix, %{key => value}, fn pfs ->
  #           Map.put(pfs, key, value)
  #         end)
  #       )
  #
  #     [_, _, _, _, "BASE_", _] ->
  #       Logger.error("Ignoring base migration not in 00 year '#{fname}'")
  #       acc
  #
  #     [_, year, pfix, index, "", label] ->
  #       put_in(acc, [:migrations, "#{year}#{pfix}#{index}"], label)
  #   end
  #   |> scan_migration_files(files)
  # end
  #
  # def scan_migration_files(acc, []), do: acc

  @stepping 10
  @minimum 100
  @maximum 9999

  defp get_include_prefix(inc) do
    case Keyword.get(inc, :prefix) do
      prefix when is_number(prefix) ->
        {:ok, prefix}

      prefix when is_binary(prefix) ->
        with {:error, reason} <- Rivet.Utils.Types.as_int(prefix) do
          {:error, "Invalid include prefix (#{reason}): #{inspect(inc)}"}
        end

      _ ->
        {:error, "Invalid or missing include prefix: #{inspect(inc)}"}
    end
  end

  defp migrations_scan_for_insert([mig | rest], {last, hist}) do
    with {:ok, prefix} <- get_include_prefix(mig) do
      last = max(prefix, last)

      case {hist[prefix], hist[mig[:include]]} do
        {nil, nil} ->
          hist = Map.merge(hist, %{prefix => mig, mig[:include] => true})
          migrations_scan_for_insert(rest, {last, hist})

        {_, true} ->
          {:exists, mig[:prefix]}

        {other, _} ->
          if other[:include] == mig[:include] do
            {:ok, prefix}
          else
            {:error, "Duplicate prefixes!\n  #{inspect(mig)}\n  #{inspect(other)}"}
          end
      end
    end
  end

  defp migrations_scan_for_insert([], {last, _hist}), do: {:ok, last + @stepping}

  def add_migration_include(file, model) when is_binary(file) and is_atom(model) do
    with {migs, _} <- Code.eval_file(file),
         {:ok, next} <- migrations_scan_for_insert(migs, {@minimum - @stepping, %{}}) do
      if next > @maximum do
        raise "Out of prefixes!"
      end

      mig = [include: model, prefix: next]

      migs =
        [mig | migs]
        |> Enum.sort(fn a, b -> Keyword.get(a, :prefix) >= Keyword.get(b, :prefix) end)

      with :ok <- File.write!(file, inspect(migs, pretty: true)) do
        {:ok, mig}
      end
    end
  end

  ##############################################################################
  # defp migration_type(prefix, keywords) when is_list(keywords),
  #   do: migration_type(prefix, Map.new(keywords))
  #
  # # support 'file' as well as module?
  # defp migration_type(prefix, %{version: v, module: m} = args) do
  #   module =
  #     case String.split("#{m}", ".") do
  #       ["Elixir", name] -> module = "#{prefix}.#{name}" |> String.to_atom()
  #       _ -> m
  #     end
  #
  #   path = Path.join("lib", pathname(module) <> ".exs")
  #
  #   case File.stat(path) do
  #     {:ok, %{type: :regular}} ->
  #       {:ok, Map.merge(args, %{path: path, module: module}) |> Map.to_list()}
  #
  #     _ ->
  #       {:error, "Cannot find migration file #{inspect(path)}"}
  #   end
  # end
  #
  # defp migration_type(_, %{include: m, prefix: p} = args) do
  #   {:ok, Map.to_list(args)}
  # end
  #
  # defp migration_type(_, mig),
  #   do: {:error, "Invalid migration type: #{inspect(Map.to_list(mig))}"}

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  # # path = Path.join("lib", Macro.underscore(to_string(module)))
  # def read_migration_sets(path, opts) do
  #   with {:ok, path} <- module_fname_as_index(path) |> module_fname_as_file(path) do
  #     File.read!(path)
  #     |> Code.string_to_quoted_with_comments(opts)
  #   end
  # end
  #
  # defp module_fname_as_index(path) do
  #   path = Path.join(path, "index.ex")
  #
  #   case File.stat(path) do
  #     {:error, _} = error -> error
  #     {:ok, %{type: :regular}} -> {:ok, path}
  #     _ -> {:error, :enoent}
  #   end
  # end
  #
  # defp module_fname_as_file({:ok, path}, _), do: {:ok, path}
  #
  # defp module_fname_as_file(_, path) do
  #   path = path <> ".ex"
  #
  #   case File.stat(path) do
  #     {:error, _} = error -> error
  #     {:ok, %{type: :file}} -> {:ok, path}
  #     _ -> {:error, :enoent}
  #   end
  # end

  ##############################################################################
  defp load_config_file(path) do
    if File.exists?(path) do
      {opts, _} = Code.eval_file(path)
      {:ok, opts}
    else
      {:error, "Cannot find file #{path}"}
    end
  end
end
