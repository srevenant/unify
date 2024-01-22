defmodule Rivet.LoaderTest do
  use Rivet.Case, async: true

  doctest Rivet.Loader, import: true

  ## FUTURE TODO
  # test "Loader" do
  #   {:ok,
  #    [
  #      %{type: "Rivet", version: 2.1},
  #      %{
  #        type: "RivetTestMod",
  #        values: %{
  #          name: "bob"
  #        }
  #      }
  #    ]}
  #   |> Rivet.Loader.load_data(Rivet.Loader.loader_state([]))
  #   |> IO.inspect
  # end
end
