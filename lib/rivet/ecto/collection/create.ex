defmodule Rivet.Ecto.Collection.Create do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ##########################################################################
      @spec create(map) :: model_p_result | ecto_p_result
      def create(attrs \\ %{}) do
        with {:ok, attrs} <- @model.change_prep(nil, attrs) do
          attrs
          |> @model.build()
          |> @repo.insert()
          |> @model.create_post(attrs)
          |> @model.change_post(attrs)
        end
      end
    end
  end
end
