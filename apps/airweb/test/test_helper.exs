Application.start :stream_data

defmodule Airweb.TestGenerators do

  use ExUnitProperties

  def generate_timesheet() do
    line_time = range()

    tag =
      ["Foo", "Bar", "Baz"]
      |> StreamData.member_of()

    day_spec = StreamData.map_of(line_time, tag, min_length: 1)
    chunk_tag = StreamData.member_of(["Mo", "Tu", "We", "Th", "Fr"])

    StreamData.map_of(chunk_tag, day_spec, min_length: 2)
  end

  def start_time() do
    gen all h <- integer(8..15), do: h
  end

  def duration_time() do
    gen all d <- integer(2..4), do: d
  end

  def quarter_time() do
    gen all m <- member_of(["00", "15", "30", "45"]), do: m
  end

  def labels() do
    StreamData.one_of([
      StreamData.tuple({ # chunk => tag present
        StreamData.constant(:start),
        StreamData.string(Enum.concat([?a..?z, ?A..?Z]), min_length: 1, max_length: 3),
        StreamData.string(Enum.concat([?a..?z, ?A..?Z]), min_length: 1, max_length: 4)
      }),
      StreamData.tuple({ # no chunk => tag present
        StreamData.constant(:append),
        StreamData.constant(:no_chunk),
        StreamData.string(Enum.concat([?a..?z, ?A..?Z]), min_length: 1, max_length: 4)
      }),
      StreamData.tuple({ # no chunk => tag absent
        StreamData.constant(:append),
        StreamData.constant(:no_chunk),
        StreamData.constant(:no_tag)
      })
    ])
  end

  def range() do
    gen all from <- integer(8..15),
      duration_h <- integer(2..4),
      duration_m1 <- member_of(["00", "15", "30", "45"]),
      duration_m2 <- member_of(["00", "15", "30", "45"]) do
        prefix =
          case from do
            f when f < 10 -> "0"
            _ -> ""
          end
        prefix <> inspect(from) <> ":" <> duration_m1 <> "-" <>
          inspect(from+duration_h) <> ":" <> duration_m2
      end
  end

  def serialize_chunk(chunk) do
    Enum.map(chunk, fn ({k,v}) -> k <> ", " <> v end)
    |> Enum.join("\n  ")
  end

  def serialize_timesheet(sheet) do
    Enum.map(sheet, fn ({k,v}) -> k <> " " <> serialize_chunk(v) end)
    #|> Enum.join("\n")
  end
end

ExUnit.start()

