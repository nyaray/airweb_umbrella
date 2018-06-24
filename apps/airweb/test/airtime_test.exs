defmodule Airweb.AirTimeTest do
  require Logger

  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Airweb.AirTime, as: AirTime

  import Airweb.TestGenerators

  doctest Airweb.AirTime

  test "that parse/1 correctly sets the fallback project on new days 1" do
    input = """
    Må 08:00, Foo
    Ti 04:00, Bar
    """
    |> String.splitter("\n", trim: true)

    assert AirTime.parse(input) ==
      {:ok, {2,
        {
          [{"Må", 8.0}, {"Ti", 4.0}], # by day
          [{"Bar", 4.0}, {"Foo", 8.0}], # by project
          [%{"Foo" => 8.0}, %{"Bar" => 4.0}], # daily project view
          12.0 # hours worked
        }
      }}
  end

  test "that parse/1 correctly sets the fallback project on new days 2" do
    input = """
    Må 08:00, Foo
    Ti 04:00, Bar
      03:00, Foo
    """
    |> String.splitter("\n", trim: true)

    assert AirTime.parse(input) ==
      {:ok, {3,
        {
          [{"Må", 8.0}, {"Ti", 7.0}],                       # by day
          [{"Bar", 4.0}, {"Foo", 11.0}],                    # by project
          [%{"Foo" => 8.0}, %{"Bar" => 4.0, "Foo" => 3.0}], # daily project view
          15.0                                              # hours worked
        }
      }}
  end

  test "that parse/1 correctly sets the fallback project on new days 3" do
    input = """
    Må 08:00, Bar
      03:00, Foo
    Ti 04:00, Bar
    """
    |> String.splitter("\n", trim: true)

    assert AirTime.parse(input) ==
      {:ok, {3,
        {
          [{"Må", 11.0}, {"Ti", 4.0}],                      # by day
          [{"Bar", 12.0}, {"Foo", 3.0}],                    # by project
          [%{"Foo" => 3.0, "Bar" => 8.0}, %{"Bar" => 4.0}], # daily project view
          15.0                                              # hours worked
        }
      }}
  end

  test "that parse/1 reports an error for first item in chunk" do
    input = """
    Må 08:00 Bar
      03:00, Foo
    Ti 04:00, Bar
    """
    |> String.splitter("\n", trim: true)

    assert AirTime.parse(input) ==
      {:ok, {3,
        {
          [{"Må", 11.0}, {"Ti", 4.0}],
          [{"Bar", 12.0}, {"Foo", 3.0}],
          [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0}],
          15.0
        }
      }}
  end

  test "that parse/1 reports an error for first item in second chunk" do
    input = """
    Må 08:00, Bar
      03:00, Foo
    Ti 04:00 Bar
      04:00, Foo
    """
    |> String.splitter("\n", trim: true)

    assert AirTime.parse(input) ==
      {:ok, {4,
        {
          [{"Må", 11.0}, {"Ti", 8.0}],
          [{"Bar", 12.0}, {"Foo", 7.0}],
          [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0, "Foo" => 4.0}],
          19.0
        }
      }}
  end

  test "that parse/1 reports an error for last item in chunk" do
    input = """
    Må 08:00, Bar
      03:00 Foo
    Ti 04:00, Bar
    """
    |> String.splitter("\n", trim: true)

    assert AirTime.parse(input) ==
      {:ok, {3,
        {
          [{"Må", 11.0}, {"Ti", 4.0}],
          [{"Bar", 12.0}, {"Foo", 3.0}],
          [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0}],
          15.0
        }
      }}
  end

  test "that parse/1 reports multiple errors for a timesheet" do
    input = """
    Må 08:00, Bar
      03:00 Foo
    Ti 04:00 Bar
    """
    |> String.splitter("\n", trim: true)

    assert AirTime.parse(input) ==
      {:ok, {3,
        {
          [{"Må", 11.0}, {"Ti", 4.0}],
          [{"Bar", 12.0}, {"Foo", 3.0}],
          [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0}],
          15.0
        }
      }}
  end

  @tag :skip
  property "five days" do
    check all days <- generate_timesheet() do
      assert is_map(days)

      sheet_string = serialize_timesheet(days)
      #if String.length(sheet_string) >= 50 do
      #  Logger.error(sheet_string)
      #end

      #assert String.length(sheet_string) < 50

      assert AirTime.parse(sheet_string) === :lol
    end
  end

end

