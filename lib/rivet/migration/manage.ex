defmodule Rivet.Migration.Manage do
  require Logger
  import Rivet.Migration
  import Rivet.Utils.Types, only: [as_int!: 1]
  alias Rivet.Mix.Templates
  import Mix.Generator
  import Transmogrify
  use Rivet

  def add_migration(model, label, {:ok, opts, _}) do
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

  def add_migration(_, _, pass), do: pass

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
end
