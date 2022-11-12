defmodule Rivet.Ecto.Collection.Delete do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ##########################################################################
      @spec delete(@model.t) :: model_p_result | ecto_p_result
      def delete(%@model{} = item) do
        @repo.delete(item)
      end

      def delete_all(clauses, opts \\ []) do
        from(t in @model, where: ^clauses)
        |> Rivet.Ecto.Collection.enrich_query_args(opts)
        |> @repo.delete_all()
      end

      def delete_all_ids(ids, opts \\ []) do
        # Returns the number of `@model` that were deleted, and a
        # list of their actual ids, which may be a subset of
        # `ids`.
        from(t in @model, where: t.id in ^ids)
        |> Rivet.Ecto.Collection.enrich_query_args(opts)
        |> @repo.delete_all()
      end
    end
  end
end
