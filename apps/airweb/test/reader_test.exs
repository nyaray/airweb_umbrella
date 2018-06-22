defmodule Airweb.ReaderTest do

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Airweb.Reader

  import Airweb.TestGenerators

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

  property "process_line parses input correctly" do
    time = gen all h <- integer(8..15), do: h
    duration = gen all d <- integer(2..4), do: d
    minute = gen all m <- member_of(["00", "15", "30", "45"]), do: m

    tag =
      gen all t_prefix <- one_of([constant(","), constant(" ")]),
              t_spaces <- string([?\s], max_length: 4),
              t_tag <- string(:alphanumeric, min_length: 1, max_length: 3) do
        t_prefix <> t_spaces <> t_tag
      end

    chunk =
      gen all c_chunk <- string(Enum.concat([?a..?z, ?A..?Z]), min_length: 1, max_length: 3),
              c_spaces <- string([?\s], min_length: 1, max_length: 4),
              c_suffix <- one_of([constant(c_chunk<>c_spaces), constant(c_spaces)]) do
        c_chunk <> c_suffix
      end

    # TODO: labels = # gen all pairs of chunk and line labels that are valid:
    #       - c begins with non-space, t has meaning
    #       - t optionally has meaning

    check all t1 <- time,
              t <- tag,
              c <- chunk,
              (c =~ ~r/^\S/ and t =~ ~r/^(,|\s)\S/) or c =~ ~r/^\s/,
              d <- duration,
              m1 <- minute,
              m2 <- minute
    do
      t2 = t1+d

      t1 = t_string t1, m1
      t2 = t_string t2, m2

      input = c <> t1 <> "-" <> t2 <> t

      range = {:range, [t1, t2]}
      tag = t |> t_strip()
      chunk = c |> t_strip()
      flag = if c =~ ~r/^\s/, do: :append, else: :start

      actual = Reader.process_line(input)
      expected = {:ok, {range, tag, flag, chunk}}
      assert actual === expected
    end
  end

  defp t_prefix(t), do: if t < 10, do: "0", else: ""
  defp t_string(t, m), do: t_prefix(t) <> inspect(t) <> ":" <> m
  defp t_strip(t), do: t |> String.replace(~r/^,/, "") |> String.trim()

end
