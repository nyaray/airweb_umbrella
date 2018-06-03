defmodule Airweb.AirTimeTest do
  use ExUnit.Case, async: true

  alias Airweb.AirTime, as: AirTime

  doctest Airweb.AirTime

  test "that parse/1 correctly sets the fallback project on new days" do
    assert AirTime.parse("Må 08:00, Foo\nTi 04:00, Bar") ==
      {:ok, {[{"Må", 8.0}, {"Ti", 4.0}], [{"Bar", 4.0}, {"Foo", 8.0}], [%{"Foo" => 8.0}, %{"Bar" => 4.0}], 12.0}}
  end
end
