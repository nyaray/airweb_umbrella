defmodule Airweb.ReaderTest do

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Airweb.Reader

  import ExUnit.CaptureLog
  import Airweb.TestGenerators

  doctest Airweb.Reader

  describe "valid chunk-starts are accepted" do

    test "comma separating tag from time" do
      assert Reader.process_line("Ti 02:15,Bar") ===
        {:ok, {{:interval, "02:15"}, "Bar", :start, "Ti"}}
    end

    test "space separating tag from time" do
      assert Reader.process_line("Ti 02:15 Bar") ===
        {:ok, {{:interval, "02:15"}, "Bar", :start, "Ti"}}
    end

    test "comma and space separating tag from time" do
      assert Reader.process_line("Ti 02:15, Bar") ===
        {:ok, {{:interval, "02:15"}, "Bar", :start, "Ti"}}
    end

  end

  describe "valid chunk-entries are accepted" do

    test "comma separating tag from space" do
      assert Reader.process_line("  14:30-17:15,Foo") ===
        {:ok, {{:range, ["14:30", "17:15"]}, "Foo", :append, :no_tag}}
    end

    test "space separating tag from time" do
      assert Reader.process_line("  14:30-17:15 Foo") ===
        {:ok, {{:range, ["14:30", "17:15"]}, "Foo", :append, :no_tag}}
    end

    test "comma and space separating tag from space" do
      assert Reader.process_line("  14:30-17:15, Foo") ===
        {:ok, {{:range, ["14:30", "17:15"]}, "Foo", :append, :no_tag}}
    end

  end

  describe "bad inputs are rejected" do

    test "that chunk-starts without tags are invalid" do
      capture_log(fn ->
        assert Reader.process_line("On 08:15-11:45") ===
          {:error, {:bad_format, "On 08:15-11:45"}}
      end)
    end

    test "that chunk-entries begin with white space" do
      capture_log(fn ->
        assert Reader.process_line("08:15-11:45,aoeu") ===
          {:error, {:bad_format, "08:15-11:45,aoeu"}}
      end)
    end

    test "that chunk-starts without separation of tag and time are rejected" do
      capture_log(fn ->
        assert Reader.process_line("On 08:15-11:45aoeu") ===
          {:error, {:bad_format, "On 08:15-11:45aoeu"}}
      end)
    end

    test "that chunk-entries without separation of tag and time are rejected" do
      capture_log(fn ->
        assert Reader.process_line("  08:15-11:45aoeu") ===
          {:error, {:bad_format, "  08:15-11:45aoeu"}}
      end)
    end

    test "that chunk starts/entries that are malformed are rejected" do
      capture_log(fn ->
        assert Reader.process_line("08:15-11:45,aoeu") ===
          {:error, {:bad_format, "08:15-11:45,aoeu"}}
      end)
    end
  end

  property "process_line parses input correctly" do
    check all t1 <- start_time(),
              d <- duration_time(),
              m1 <- quarter_time(),
              m2 <- quarter_time(),
              {flag, c, tag} <- labels(),
              chunk_pad <- string([9, 32], min_length: 1, max_length: 2),
              tag_pad <- string([9, 32], max_length: 2)
    do
      from = t_string(t1, m1)
      to = t_string((t1 + d), m2)

      chunk = if c === :no_tag, do: "", else: t_strip(c)
      tag_pad = if tag_pad === "" and tag !== "", do: ",", else: tag_pad

      input = chunk <> chunk_pad <> from <> "-" <> to <> tag_pad <> tag
      assert Reader.process_line(input) ===
        {:ok, {{:range, [from, to]}, tag, flag, c}}
    end
  end

  defp t_prefix(t), do: if t < 10, do: "0", else: ""
  defp t_string(t, m), do: t_prefix(t) <> inspect(t) <> ":" <> m
  defp t_strip(t), do: t |> String.replace(~r/^,/, "") |> String.trim()

end
