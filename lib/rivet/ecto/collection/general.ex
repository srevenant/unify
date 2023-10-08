defmodule Rivet.Ecto.Collection.General do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ##########################################################################
      @spec exists?(claims_or_query :: keyword() | term()) :: true | false
      def exists?(clauses) when is_list(clauses),
        do: from(@model, where: ^clauses) |> @repo.exists?()

      ##########################################################################
      def count!(), do: @repo.aggregate(@model, :count, :id)

      def count!(claims), do: @repo.aggregate(from(p in @model, where: ^claims), :count, :id)

      def aggregate(x, y), do: @repo.aggregate(x, y)

      ##########################################################################
      # use judiciously
      def full_table_scan(clauses, func) do
        stream = @repo.stream(from(p in @model, where: ^clauses))

        @repo.transaction(
          fn ->
            stream
            |> Stream.each(func)
            |> Stream.run()
          end,
          timeout: :infinity
        )
      end

      ##########################################################################
      def associate(%@model{} = item, var, value) do
        item
        |> cast(%{}, [])
        |> put_assoc(var, value)
        |> @repo.update()
        |> case do
          {:ok, record} -> record
          o -> o
        end
      end

      ##########################################################################
      @spec preload!(@model.t, preloads :: term(), opts :: Keyword.t()) :: @model.t
      def preload!(item, preloads, opts \\ []),
        do: @repo.preload(item, preloads, opts)

      @spec preload(@model.t, preloads :: term(), opts :: Keyword.t()) ::
              model_p_result | ecto_p_result
      def preload(item, preloads, opts \\ []) do
        {:ok, @repo.preload(item, preloads, opts)}
      rescue
        err -> {:error, err}
      end

      ##########################################################################
      @dialyzer {:nowarn_function, [unload: 1]}
      def unload(item) do
        @model.__schema__(:associations)
        |> Enum.reduce(item, fn assoc, item -> unload(item, assoc) end)
      end

      @dialyzer {:nowarn_function, [unload: 2]}
      def unload(item, assoc) do
        %{
          cardinality: cardinality,
          field: field,
          owner: owner
        } = @model.__schema__(:association, assoc)

        %{
          item
          | assoc => %Ecto.Association.NotLoaded{
              __cardinality__: cardinality,
              __field__: field,
              __owner__: owner
            }
        }
      end

      ##########################################################################
      def reload(%@model{} = item) do
        case @repo.reload(item) do
          %@model{} = item -> {:ok, item}
          nil -> {:error, :not_found}
        end
      end
    end
  end
end
