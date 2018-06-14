defmodule Airweb.ReaderTest do

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Airweb.Reader

  doctest Airweb.Reader

  test "that a valid start of a chunk is correctly processed" do
    assert Reader.process_line("Ti 02:15, Bar") ===
      {:ok, {{:interval, "02:15"}, "Bar", :start, "Ti"}}
  end

  test "that a chunk item is correctly processed" do
    assert Reader.process_line("  14:30-17:15, Foo") ===
      {:ok, {{:range, ["14:30", "17:15"]}, "Foo", :append, :no_tag}}
  end

  test "that invalid input is rejected" do
    assert Reader.process_line("On 08:15-11:45") ===
      {:error, {:bad_format, "On 08:15-11:45"}}
  end

end
