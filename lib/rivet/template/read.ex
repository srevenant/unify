defmodule Rivet.Template.Read do
  @moduledoc """
  Reads Rivet Template high-level structure. See Rivet.Template for more info.
  """

  def as_trim_key(key) when is_atom(key), do: key
  def as_trim_key(key), do: String.trim(key) |> Transmogrify.snakecase() |> String.to_atom()

  def from_file(path) when is_binary(path) do
    with {:ok, fd} <- File.open(path, [:utf8, :read]), do: from(IO.stream(fd, :line))
  end

  def from_string(data) when is_binary(data) do
    with {:ok, pid} <- StringIO.open(data), do: from(IO.stream(pid, :line))
  end

  defp from(stream) do
    with {{label, buf}, hist} <- Enum.reduce_while(stream, nil, &read_sections/2) do
      case [{as_trim_key(label), Enum.reverse(buf)} | hist] |> Enum.reverse() do
        [{:meta, meta} | body] ->
          with {:ok, meta} <- YamlElixir.read_from_string(meta),
               do: {:ok, Transmogrify.transmogrify(meta), body}

        _ ->
          {:error, "Template appears to be missing meta section"}
      end
    end
  end

  defp read_sections("=== " <> next_label, {{last_label, buf}, prev}),
    do: {:cont, {{next_label, []}, [{as_trim_key(last_label), Enum.reverse(buf)} | prev]}}

  defp read_sections(line, {{label, buf}, prev}), do: {:cont, {{label, [line | buf]}, prev}}
  defp read_sections("=== rivet-template-v1" <> _, nil), do: {:cont, {{:meta, []}, []}}

  defp read_sections(line, nil), do: {:halt, {:error, "Not a Rivet Template: #{line}"}}
end
