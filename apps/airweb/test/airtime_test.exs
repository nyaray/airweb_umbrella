defmodule Airweb.AirTimeTest do
  use ExUnit.Case, async: true

  alias Airweb.AirTime, as: AirTime

  doctest Airweb.AirTime

  test "that parse/1 correctly sets the fallback project on new days" do
    assert AirTime.parse("Må 08:00, Foo\n  Ti 04:00, Bar") ==
      {:ok, :lol}
  end
end
