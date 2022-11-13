defmodule Rivet.Ecto.Context do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @table_prefix Application.compile_env!(:rivet, :table_prefix) || ""
    end
  end
end
