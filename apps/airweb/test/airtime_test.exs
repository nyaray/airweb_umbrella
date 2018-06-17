defmodule Airweb.AirTimeTest do
  require Logger

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

  test "that parse/1 reports an error for first item in chunk" do
    input = """
    Må 08:00 Bar
      03:00, Foo
    Ti 04:00, Bar
    """

    assert AirTime.parse(input) ==
      {:ok, {
        [{"Må", 11.0}, {"Ti", 4.0}],
        [{"Bar", 12.0}, {"Foo", 3.0}],
        [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0}],
        15.0
      }}
  end

  test "that parse/1 reports an error for first item in second chunk" do
    input = """
    Må 08:00, Bar
      03:00, Foo
    Ti 04:00 Bar
      04:00, Foo
    """

    assert AirTime.parse(input) ==
      {:ok, {
        [{"Må", 11.0}, {"Ti", 8.0}],
        [{"Bar", 12.0}, {"Foo", 7.0}],
        [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0, "Foo" => 4.0}],
        19.0
      }}
  end

  test "that parse/1 reports an error for last item in chunk" do
    input = """
    Må 08:00, Bar
      03:00 Foo
    Ti 04:00, Bar
    """

    assert AirTime.parse(input) ==
      {:ok, {
        [{"Må", 11.0}, {"Ti", 4.0}],
        [{"Bar", 12.0}, {"Foo", 3.0}],
        [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0}],
        15.0
      }}
  end

  test "that parse/1 reports multiple errors for a timesheet" do
    input = """
    Må 08:00, Bar
      03:00 Foo
    Ti 04:00 Bar
    """

    assert AirTime.parse(input) ==
      {:ok, {
        [{"Må", 11.0}, {"Ti", 4.0}],
        [{"Bar", 12.0}, {"Foo", 3.0}],
        [%{"Bar" => 8.0, "Foo" => 3.0}, %{"Bar" => 4.0}],
        15.0
      }}
  end

  #defp time2string({:range, [from, to]}), do: "#{from}-#{to}"
  #defp time2string({:interval, i}), do: "00:00-#{to}"

  #defp generate_timesheet() do
  #  line_time =
  #    gen all from <- integer(8..15),
  #            duration_h <- integer(2..4),
  #            duration_m1 <- member_of(["0", "15", "30", "45"]),
  #            duration_m2 <- member_of(["0", "15", "30", "45"]) do
  #              inspect(from) <> ":" <> duration_m1 <> "-" <>
  #                inspect(from+duration_h) <> ":" <> duration_m2
  #    end

  #  line_tag = StreamData.string(Enum.concat([?a..?z, ?A..?Z]), length: 4)
  #  tag =
  #    ["aa", "hh", "zz"]
  #    |> StreamData.member_of()

  #  day_spec = StreamData.map_of(line_time, line_tag)
  #  chunk_tag = StreamData.string(Enum.concat([?a..?z, ?A..?Z]), length: 2)

  #  StreamData.map_of(chunk_tag, day_spec, min_length: 2)
  #end

  #defp serialize_chunk(chunk) do
  #end

  #defp serialize_timesheet(sheet) do
  #  keys = Map.keys sheet
  #  Enum.map(sheet, fn ())
  #end

  #property "five days" do
  #  check all days <- generate_timesheet() do
  #    assert is_map(days)
  #    assert Enum.count(Map.keys(days)) < 5
  #  end
  #end

end

