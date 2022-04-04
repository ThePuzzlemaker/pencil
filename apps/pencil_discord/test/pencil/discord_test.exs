defmodule Pencil.DiscordTest do
  use ExUnit.Case
  doctest Pencil.Discord

  test "greets the world" do
    assert Pencil.Discord.hello() == :world
  end
end
