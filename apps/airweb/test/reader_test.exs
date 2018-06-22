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

    labels =
      StreamData.one_of([
        StreamData.tuple({ # chunk => tag present
          StreamData.constant(:start),
          StreamData.string(Enum.concat([?a..?z, ?A..?Z]), min_length: 1, max_length: 3),
          StreamData.string(Enum.concat([?a..?z, ?A..?Z]), min_length: 1, max_length: 4)
        }),
        StreamData.tuple({ # no chunk => tag present
          StreamData.constant(:append),
          StreamData.constant(:no_tag),
          StreamData.string(Enum.concat([?a..?z, ?A..?Z]), min_length: 1, max_length: 4)
        }),
        StreamData.tuple({ # no chunk => tag absent
          StreamData.constant(:append),
          StreamData.constant(:no_tag),
          StreamData.constant("")
        })
      ])

    check all t1 <- time,
              d <- duration,
              m1 <- minute,
              m2 <- minute,
              {flag, c, tag} <- labels,
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
