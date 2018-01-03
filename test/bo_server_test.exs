defmodule BOServerTest do
  use ExUnit.Case
  doctest BOServer

  test "greets the world" do
    assert BOServer.hello() == :world
  end
end
