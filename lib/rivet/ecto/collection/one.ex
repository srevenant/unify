defmodule Rivet.Ecto.Collection.One do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ##########################################################################
      if Keyword.get(opts, :id_type, :uuid) == :uuid do
        @type id :: Ecto.UUID.t()

        @spec one!(id | keyword()) :: nil | @model.t()
        def one!(id) when is_binary(id), do: inner_one!([id: id], [])

        def one!(id, preload) when is_binary(id) and is_list(preload),
          do: inner_one!([id: id], preload)

        def one!(any, preload_atom) when is_atom(preload_atom),
          do: inner_one!(any, [preload_atom])

        def one!(clauses) when is_list(clauses), do: inner_one!(clauses, [])

        def one!(clauses, preload) when is_list(clauses) and is_list(preload),
          do: inner_one!(clauses, preload)

        @spec one(id | keyword(), list() | atom()) ::
                {:ok, @model.t()} | {:error, String.t()}
        def one(id) when is_binary(id), do: inner_one([id: id], [])

        def one(id, preload) when is_binary(id) and is_list(preload),
          do: inner_one([id: id], preload)

        def one(any, preload_atom) when is_atom(preload_atom), do: inner_one(any, [preload_atom])
        def one(clauses) when is_list(clauses), do: inner_one(clauses, [])

        def one(clauses, preload) when is_list(clauses) and is_list(preload),
          do: inner_one(clauses, preload)
      else
        @type id :: integer

        @spec one!(id | keyword()) :: nil | @model.t()
        def one!(id) when is_integer(id), do: inner_one!([id: id], [])

        def one!(id, preload) when is_integer(id) and is_list(preload),
          do: inner_one!([id: id], preload)

        def one!(any, preload_atom) when is_atom(preload_atom),
          do: inner_one!(any, [preload_atom])

        def one!(clauses) when is_list(clauses), do: inner_one!(clauses, [])

        def one!(clauses, preload) when is_list(clauses) and is_list(preload),
          do: inner_one!(clauses, preload)

        @spec one(id | keyword(), list() | atom()) ::
                {:ok, @model.t()} | {:error, String.t()}
        def one(id) when is_integer(id), do: inner_one([id: id], [])

        def one(id, preload) when is_integer(id) and is_list(preload),
          do: inner_one([id: id], preload)

        def one(any, preload_atom) when is_atom(preload_atom), do: inner_one(any, [preload_atom])
        def one(clauses) when is_list(clauses), do: inner_one(clauses, [])

        def one(clauses, preload) when is_list(clauses) and is_list(preload),
          do: inner_one(clauses, preload)
      end

      defp inner_one!(clauses, preload) when is_list(clauses) and is_list(preload) do
        @repo.one!(from(@model, where: ^clauses, preload: ^preload))
      rescue
        err -> {:error, err}
      end

      defp inner_one(clauses, preload) do
        case @repo.one(from(@model, where: ^clauses, preload: ^preload)) do
          nil -> {:error, "Nothing found"}
          result -> {:ok, result}
        end
      rescue
        err -> {:error, err}
      end
    end
  end
end
