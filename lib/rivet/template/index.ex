defmodule Rivet.Template do
  alias Rivet.Template.{Evaluate, Read}

  @moduledoc """

  Rivet Templates. Structure:

  * `^=== (.*)$`  is the delimiter, where the captured part is the section label
  * First line of file MUST be `=== rivet-template-v1`
  * Delimiter of equals vs dashes so that individual sections may include yaml
    which has multiple yaml docs within.
  * First section is a "meta" section defining the other sections in any order,
    matching off the key:value pair where the key is the section label, and the
    value of the key:value pair represents the type of data within that section.

  ```
  sections:
    - constants: yml
    - inputs: eex-yml
    - rack: eex-yml
  ```

  With this example there would be a total of four sections in the template
  (the first being this spec), and the next three are labelled as shown.

  """

  def load_file(path, opts \\ []),
    do: Read.from_file(path) |> parse(opts)

  def load_string(string, opts \\ []),
    do: Read.from_string(string) |> parse(opts)

  ##############################################################################
  @default_opts %{sections: :all, imports: [], assigns: %{}}
  defp parse({:ok, meta, body}, opts),
    do: with({:ok, opts} <- handle_opts(opts, meta), do: parse_sections({%{}, []}, body, opts))

  defp parse(pass, _), do: pass

  ##############################################################################
  defp handle_opts(opts, %{sections: sections} = meta) do
    meta = Map.delete(meta, :sections)

    @default_opts
    |> Map.merge(Map.new(opts))
    |> Evaluate.preparse_imports()
    |> Map.put(:meta, meta)
    |> case do
      %{sections: :all} = opts ->
        {:ok, Map.put(opts, :sections, sections)}

      %{sections: list} = opts when is_list(list) ->
        {:ok, Map.put(opts, :sections, Map.take(sections, list))}

      %{sections: map} = opts when is_map(map) ->
        {:ok, opts}
    end
  end

  defp handle_opts(_, _), do: {:error, "Invalid Template: missing meta sections"}

  ##############################################################################
  defp parse_sections({out, defer}, [{label, body} | rest], %{sections: sections} = opts)
       when is_map_key(sections, label) do
    case sections[label] do
      "yml" -> with {:ok, data} <- parse_yaml(body), do: {Map.put(out, label, data), defer}
      "eex-yml" -> {out, [{label, body} | defer]}
      "eex-yml-docs" -> {out, [{label, body} | defer]}
      "eex" -> {out, [{label, body} | defer]}
    end
    |> parse_sections(rest, opts)
  end

  # not a section which was asked for
  defp parse_sections(out, [{_, _} | rest], opts), do: parse_sections(out, rest, opts)

  # we are done with the first pass
  defp parse_sections({out, defer}, [], opts), do: handle_deferred(out, defer, opts)

  # something errored earlier
  defp parse_sections(error, _, _), do: error

  ##############################################################################
  defp parse_yaml(data, method \\ :read_from_string) do
    with {:ok, data} <- apply(YamlElixir, method, [data]) do
      {:ok, Transmogrify.transmogrify(data)}
    end
  end

  ##############################################################################
  defp handle_deferred(out, [{label, defer} | rest], %{sections: sections} = opts) do
    with {:ok, result} <- Evaluate.evaluate(defer, opts, out) do
      method =
        case sections[label] do
          "eex-yml" -> :read_from_string
          "eex-yml-docs" -> :read_all_from_string
          "eex" -> :none
        end

      if method == :none do
        Map.put(out, label, result) |> handle_deferred(rest, opts)
      else
        with {:ok, data} <- parse_yaml(result, method),
             do: Map.put(out, label, data) |> handle_deferred(rest, opts)
      end
    end
  end

  defp handle_deferred(out, [], _), do: {:ok, out}
  defp handle_deferred(error, _, _), do: error
end
