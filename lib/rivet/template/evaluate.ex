defmodule Rivet.Template.Evaluate do
  @moduledoc false
  def evaluate(list, opts, sections) when is_list(list),
    do: Enum.join(list) |> evaluate(opts, sections)

  def evaluate(string, %{imports: imports, assigns: assigns}, sections) do
    try do
      {:ok, EEx.eval_string(imports <> string, assigns: Map.merge(assigns, sections))}
    rescue
      err ->
        {:error, {err, __STACKTRACE__}}
    end
  end

  @always_imports ["Transmogrify", "Transmogrify.As"]
  def preparse_imports(%{imports: imports} = opts) when is_list(imports) do
    imports =
      MapSet.new(@always_imports ++ imports)
      |> MapSet.to_list()
      |> Enum.map(&"import #{&1}")
      |> Enum.join(";")

    %{opts | imports: "<% #{imports} %>"}
  end
end
