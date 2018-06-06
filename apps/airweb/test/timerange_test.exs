defmodule Airweb.TimeRangeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  require Logger

  alias Airweb.TimeRange, as: TimeRange

  doctest TimeRange

  test "that from_interval correctly handles incorrect input" do
    capture_log(fn ->
      assert TimeRange.from_interval("aoeu") === {:error, :invalid_format}
    end)
  end

  test "that from_range correctly handles incorrect input" do
    capture_log(fn ->
      assert TimeRange.from_range(["aoeu", "htns"]) === {:error, :invalid_format}
    end)
  end

end

