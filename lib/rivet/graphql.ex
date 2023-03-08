defmodule Rivet.Graphql do
  @moduledoc """
  Helper functions for Absinthe resolvers.
  """
  require Logger

  def current_hostname(%{context: %{hostname: h}}) when not is_nil(h), do: {:ok, h}
  def current_hostname(_), do: {:error, "No Host on session"}

  def optional_arg(map, arg) do
    case Map.get(map, arg) do
      nil -> []
      value -> [{arg, value}]
    end
  end

  def ok_as_list({:error, "Nothing found"}), do: {:ok, []}
  def ok_as_list({:ok, result}), do: {:ok, [result]}
  def ok_as_list(pass), do: pass

  def parse_enum(%{value: value}, enum) do
    enum.cast(value)
  end

  def parse_enum(_, _), do: :error

  def parse_atom(%{value: value}) do
    {:ok, String.to_existing_atom(value)}
  rescue
    _ ->
      :error
  end

  def parse_atom(_), do: :error

  @std_errors %{authn: "Unauthenticated", authz: "Unauthorized", args: "Invalid Arguments"}
  def error_string(errs) when is_list(errs) do
    Enum.map_join(errs, ",", &error_string/1)
  end

  def error_string(%Ecto.Changeset{} = chgset) do
    Ecto.Changeset.traverse_errors(chgset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", value)
      end)
    end)
    |> flatten_errors([], [])
    |> Enum.join(", ")
  end

  def error_string(%ArgumentError{message: m}), do: m

  def error_string(user) when is_struct(user), do: @std_errors[:authz]
  def error_string(reason) when is_atom(reason), do: @std_errors[reason]
  def error_string(reason) when is_binary(reason), do: reason
  def error_string(reason) when is_exception(reason), do: Exception.message(reason)

  def graphql_result({:ok, _} = pass, _), do: pass
  def graphql_result({:error, reason}, method), do: graphql_error(method, reason)

  def graphql_status_result(state, method \\ nil)

  def graphql_status_result({:error, "Unauthenticated"} = pass, _), do: pass
  def graphql_status_result({:ok, %{success: a}} = pass, _) when is_boolean(a), do: pass
  def graphql_status_result({:ok, result}, _), do: {:ok, %{success: true, result: result}}

  def graphql_status_result({:error, err}, _),
    do: {:ok, %{success: false, reason: error_string(err)}}

  def graphql_error(method, err, logargs \\ []) do
    reason = error_string(err)
    graphql_log(method, [failure: reason] ++ logargs)
    {:error, reason}
  end

  def graphql_log(method, args \\ [])

  def graphql_log(nil, _), do: :ok

  def graphql_log(method, args), do: Logger.info("graphql", [{:method, method} | args])

  defp flatten_errors(errs, p, out) when is_map(errs) do
    Map.to_list(errs)
    |> flatten_errors(p, out)
  end

  defp flatten_errors([elem | rest], p, out) when is_map(elem) do
    elem_out = flatten_errors(elem, p, out)
    flatten_errors(rest, p, elem_out)
  end

  defp flatten_errors([msg | rest], prefixes, out) when is_binary(msg) do
    prefix = Enum.reverse(prefixes) |> Enum.join(".")
    msg_out = "#{prefix} #{msg}"
    flatten_errors(rest, prefixes, [msg_out | out])
  end

  defp flatten_errors([{k, v} | rest], prefixes, out) when is_map(v) or is_list(v) do
    elem_out = flatten_errors(v, [to_string(k) | prefixes], out)
    flatten_errors(rest, prefixes, elem_out)
  end

  defp flatten_errors([], _, out), do: out
end
