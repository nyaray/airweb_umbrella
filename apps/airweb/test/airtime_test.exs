defmodule Airweb.AirTimeTest do

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Airweb.AirTime, as: AirTime

  doctest Airweb.AirTime

  test "that parse/1 correctly sets the fallback project on new days 1" do
    input = """
    Må 08:00, Foo
    Ti 04:00, Bar
    """

    assert AirTime.parse(input) ==
      {:ok, {
        [{"Må", 8.0}, {"Ti", 4.0}], # by day
        [{"Bar", 4.0}, {"Foo", 8.0}], # by project
        [%{"Foo" => 8.0}, %{"Bar" => 4.0}], # daily project view
        12.0}} # hours worked
  end

  test "that parse/1 correctly sets the fallback project on new days 2" do
    input = """
    Må 08:00, Foo
    Ti 04:00, Bar
      03:00, Foo
    """

    assert AirTime.parse(input) ==
      {:ok, {
        [{"Må", 8.0}, {"Ti", 7.0}],                       # by day
        [{"Bar", 4.0}, {"Foo", 11.0}],                    # by project
        [%{"Foo" => 8.0}, %{"Bar" => 4.0, "Foo" => 3.0}], # daily project view
        15.0}}                                            # hours worked
  end

  test "that parse/1 correctly sets the fallback project on new days 3" do
    input = """
    Må 08:00, Bar
      03:00, Foo
    Ti 04:00, Bar
    """

    assert AirTime.parse(input) ==
      {:ok, {
        [{"Må", 11.0}, {"Ti", 4.0}],                      # by day
        [{"Bar", 12.0}, {"Foo", 3.0}],                    # by project
        [%{"Foo" => 3.0, "Bar" => 8.0}, %{"Bar" => 4.0}], # daily project view
        15.0}}                                            # hours worked
  end

  #def generate_timesheet() do
  #  alpha =
  #    [?a..?z, ?A..?Z]
  #    |> Enum.concat
  #    |> StreamData.string
  #  alpha_pair = StreamData.list_of(alpha, length: 2)
  #end

  #property "testing" do
  #  check all sheet <- generate_timesheet() do
  #    assert Enum.length(sheet) == 4
  #  end
  #end

end
