defmodule Rivet.Mix.Migration do
  @moduledoc false
  require Logger
  import Rivet.Mix.Common

  @default_step 100
  @default_index %{schemas: %{}, migrations: %{}}

  def link_next_schema(schema_file, name, migdir, prefix, order) when prefix < 100 do
    prefix = String.pad_leading("#{prefix}", 2, "0")
    migrations = list_migrations(migdir)

    schemas =
      case get_in(migrations, [:schemas, prefix]) do
        nil -> %{}
        val -> val
      end

    next =
      if is_nil(order) do
        case migrations do
          %{next: %{^prefix => next}} -> format_schema_index(prefix, next)
          _ -> format_schema_index(prefix, 0)
        end
      else
        format_schema_index(prefix, order)
      end

    if Map.has_key?(schemas, next) do
      {:error, "Cannot use index `#{next}` for schema order as it's already taken"}
    else
      backstep = nodot(migdir) |> Enum.map(fn _ -> ".." end) |> Path.join()
      schema = nodot(schema_file) |> Path.join()

      File.ln_s("#{backstep}/#{schema}", "#{migdir}/#{next}_BASE_#{name}.exs")
    end
  end

  def link_next_schema(_, _, _, _, _), do: {:error, "Invalid link options"}

  ##############################################################################
  def format_schema_index(prefix, order) when order < 1_000_000_000,
    do: "00" <> String.pad_leading("#{prefix}", 2, "0") <> String.pad_leading("#{order}", 10, "0")

  def format_schema_index(_, order), do: raise("order (#{order}) is out of bounds")

  def format_migration_index(), do: Timex.now() |> Timex.format("{YYYY}{M}{0D}{h24}{m}{s}")

  def list_migrations(folder, step \\ @default_step) do
    case File.ls(folder) do
      {:ok, files} ->
        result = scan_migration_files(@default_index, files)

        Map.put(
          result,
          :next,
          Enum.reduce(result.schemas, %{}, fn {prefix, schemas}, acc ->
            next = get_next_schema(schemas)
            Map.put(acc, prefix, next + step)
          end)
        )

      _error ->
        {:error, "failure listing files"}
    end
  end

  defp get_next_schema(schemas) do
    schemas
    |> Enum.map(fn {_, %{index: o}} -> o end)
    |> Enum.sort()
    |> Enum.reverse()
    |> case do
      [last | _] -> last
      _ -> 0
    end
  end

  ##############################################################################
  def scan_migration_files(acc, [fname | files]) do
    case Regex.run(~r/^(\d\d)(\d\d)([0-9]+)_?(BASE_)?(.*).exs$/i, fname) do
      nil ->
        Logger.debug("Ignoring unmatched migration file '#{fname}'")
        acc

      [_, "00", pfix, index, "BASE_", label] ->
        key = "00#{pfix}#{index}"
        value = %{prefix: String.to_integer(pfix), index: String.to_integer(index), label: label}

        Map.replace(
          acc,
          :schemas,
          Map.update(acc.schemas, pfix, %{key => value}, fn pfs ->
            Map.put(pfs, key, value)
          end)
        )

      [_, _, _, _, "BASE_", _] ->
        Logger.error("Ignoring base migration not in 00 year '#{fname}'")
        acc

      [_, year, pfix, index, "", label] ->
        put_in(acc, [:migrations, "#{year}#{pfix}#{index}"], label)
    end
    |> scan_migration_files(files)
  end

  def scan_migration_files(acc, []), do: acc
end
