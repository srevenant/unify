defmodule Rivet.Loader do
  alias Rivet.Loader.State
  import Rivet.Loader.Tools

  @module_prefix "Elixir.Rivet."

  @callback load_data(meta :: State.t(), data :: map()) :: {:ok | :error, meta :: State.t()}
  @callback load_deferred(meta :: State.t(), data :: map()) :: {:ok | :error, meta :: State.t()}
  @optional_callbacks load_deferred: 2

  @min_version 2.1
  @max_version 2.1

  def load_file(fname, opts \\ []) do
    case find_load_file(fname) do
      {:error, reason} ->
        IO.puts(:stderr, reason)
        {:error, %{log: [reason]}}

      {:ok, path} ->
        YamlElixir.read_all_from_file(path, atoms: false)
        |> handle_yaml_result
        |> load_data(loader_state(opts ++ [path: path]))
        |> handle_exit
    end
  end

  defp handle_exit({how, %{log: log} = state}),
    do: {how, Map.put(state, :log, Enum.reverse(log))}

  ##############################################################################
  def loader_state(attrs) do
    case State.build(attrs) do
      %{path: path} = state when is_binary(path) ->
        log(state, "==> DATA from #{path}\n")

      state ->
        state
    end
  end

  ##############################################################################
  # expects a sequence of docs
  @spec load_data({:ok, docs :: list()} | {:error, msg :: binary()}, state :: State.t()) ::
          {:ok | :error, state :: State.t()}

  def load_data({:error, msg}, %State{} = state), do: abort(state, msg)

  def load_data({:ok, [%{version: version, type: "Rivet"} | data]}, %State{} = state)
      when @min_version <= version and version <= @max_version,
      do: load_data_items({:ok, state}, data)

  def load_data({:ok, _}, %State{} = state),
    do: {:error, log(state, "Unrecognized config file (version or type missing?)")}

  ##############################################################################
  defp valid_load_result({q, %State{}} = pass, _, _) when q in [:ok, :error], do: pass

  defp valid_load_result(result, type, func) do
    IO.inspect(result, label: "\n=> FAILURE from #{type}.#{func}(), bad result")
    system_exit(1)
  end

  def load_data_items({:ok, %State{} = state}, [%{type: type, values: data} | rest]) do
    model = String.to_atom("#{@module_prefix}.#{type}")
    loader = String.to_atom("#{model}.Loader")

    cond do
      Kernel.function_exported?(loader, :load_data, 2) ->
        apply(loader, :load_data, [state, data])
        |> valid_load_result(type, :load_data)

      Kernel.function_exported?(model, :create, 1) ->
        load_model_direct(model, data, state)

      true ->
        {:error, {state, "Cannot find module to load: #{type}", nil}}
    end
    |> load_data_items(rest)
  end

  # ignore empty doc
  def load_data_items({:ok, %State{}} = pass, [x | rest]) when map_size(x) == 0,
    do: load_data_items(pass, rest)

  def load_data_items({:error, {%State{} = state, msg, data}}, _), do: abort(state, msg, data)
  def load_data_items({:error, %State{} = state} = error, _) when is_map(state), do: error

  def load_data_items({:ok, %State{deferred: deferred} = state}, []),
    do: load_deferred({:ok, state}, deferred)

  # doc exists but didn't match format
  def load_data_items({:ok, %State{} = state}, _) do
    {:error, log(state, "Unrecognized doc, no type/values, cannot continue")}
  end

  ##############################################################################
  defp load_model_direct(model, data, %State{} = state) do
    name =
      case data do
        %{name: name} -> [name: name]
        %{label: label} -> [name: label]
        _ -> []
      end

    with {:ok, _, state} <- upsert_record(state, model, data, name), do: {:ok, state}
  end

  ##############################################################################
  def load_deferred({:ok, %State{} = state}, [%{type: mod} = data | rest]) do
    apply(mod, :load_deferred, [state, data])
    |> valid_load_result(mod, :load_deferred)
    |> load_deferred(rest)
  end

  def load_deferred({_, %State{}} = pass, _), do: pass

  ##############################################################################
  # defp defer_config(%State{} = state, %{id: id, mod: mod}) do
  #   with %{handlers: %{init: init} = h} = cached <- get_in(state, [:cache, mod, id]) do
  #     mod = Module.safe_concat([init])
  #     %{state | inits: [%{cached | handlers: Map.put(h, :init, mod)} | state.inits]}
  #   else
  #     _ ->
  #       state
  #   end
  # end

  # defp cache_data(state, mod, data), do: {:ok, cache_put(state, mod, data, data.id), data}
  #
  # defp cache_put(state, mod, data, key) do
  #   {state, mod_cache} =
  #     if Map.has_key?(state, :cache) do
  #       {state, get_in(state, [:cache, mod]) || %{}}
  #     else
  #       {Map.put(state, :cache, %{}), %{}}
  #     end
  #
  #   put_in(state, [:cache, mod], Map.put(mod_cache, key, data))
  # end
end
