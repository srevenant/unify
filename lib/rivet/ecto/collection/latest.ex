defmodule Rivet.Ecto.Collection.Latest do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      def latest!(claims \\ [], x \\ 1) do
        from(m in @model,
          where: ^claims,
          order_by: [desc: m.inserted_at],
          limit: ^x
        )
        |> @repo.all()
      end

      def latest(claims \\ [], x \\ 1), do: {:ok, latest!(claims, x)}
    end
  end
end
