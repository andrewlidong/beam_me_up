defmodule BeamConcurrencyTest do
  use ExUnit.Case
  doctest BeamConcurrency

  test "greets the world" do
    assert BeamConcurrency.hello() == :world
  end
end
