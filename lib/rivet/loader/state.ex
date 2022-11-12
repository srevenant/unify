defmodule Rivet.Loader.State do
  defstruct tenant_id: nil,
            tenants: %{},
            deferred: [],
            defer: nil,
            commit: nil,
            loaded: %{},
            previous: %{},
            path: nil,
            inits: [],
            # "logs" go here and are returned in the state
            log: []

  @type t :: %__MODULE__{
          tenant_id: nil | binary(),
          tenants: map(),
          deferred: list(),
          defer: nil | function(),
          commit: nil | function(),
          loaded: map(),
          previous: map(),
          path: nil | binary(),
          inits: list(),
          log: list()
        }

  def build(data) do
    struct(__MODULE__, data)
  end
end
