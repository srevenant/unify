defmodule Rivet.Migration do
  import Transmogrify
  require Logger
  use Rivet

  defstruct base: false,
            version: 0,
            index: nil,
            prefix: nil,
            parent: nil,
            model: nil,
            module: nil,
            path: nil,
            include: nil,
            external: nil,
            migrations: nil

  @type t :: %__MODULE__{
          base: boolean(),
          version: integer(),
          index: nil | String.t(),
          prefix: nil | integer(),
          parent: nil | module(),
          model: nil | module(),
          module: nil | module(),
          path: nil | String.t(),
          include: nil | module(),
          external: nil | String.t(),
          migrations: nil | list()
        }

  # amazing that elixir still suffers with built-in time formatting; I don't
  # want to bring in a third-party lib, so just use posix time for now
  # is there something native to elixir that allows me to get this datestamp
  # in local system timezone without jumping through a bunch of hoops?
  def datestamp() do
    case System.cmd("date", ["+%0Y%0m%0d%0H%0M%0S"]) do
      {ts, 0} -> String.trim(ts)
    end
  end

  def maxlen_in(list, func \\ & &1),
    do: Enum.reduce(list, 0, fn i, x -> max(String.length(func.(i)), x) end)

  def as_module(name), do: "Elixir.#{modulename(name)}" |> String.to_atom()

  def module_extend(parent, mod), do: as_module("#{modulename(parent)}.#{modulename(mod)}")

  def module_pop(mod),
    do: String.split("#{mod}", ".") |> Enum.slice(0..-2) |> Enum.join(".") |> as_module()

  def pad(s, w, fill \\ "0")
  def pad(s, w, fill) when is_binary(s) and w < 0, do: String.pad_trailing(s, abs(w), fill)
  def pad(s, w, fill) when is_binary(s), do: String.pad_leading(s, w, fill)
  def pad(s, w, fill) when w < 0, do: String.pad_trailing("#{s}", abs(w), fill)
  def pad(s, w, fill), do: String.pad_leading("#{s}", w, fill)

  def migration_model(mod) do
    case String.split("#{mod}", ".") |> Enum.reverse() do
      ["Migrations", model | _] -> model
      [model | _] -> model
    end
  end

  def nodot(path) do
    case Path.split(path) do
      ["." | rest] -> rest
      rest -> rest
    end
  end

  @spec load_data_file(String.t()) :: {:ok, list(list())} | rivet_error()
  def load_data_file(path) do
    if File.exists?(path) do
      case Code.eval_file(path) do
        {opts, _} when is_list(opts) -> {:ok, opts}
        _ -> {:error, "Cannot load file #{path}: Invalid contents"}
      end
    else
      {:error, "Cannot find file #{path}"}
    end
  end
end
