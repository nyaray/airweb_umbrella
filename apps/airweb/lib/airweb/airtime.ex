defmodule Airweb.AirTime do
  require Logger

  alias Airweb.TimeRange, as: TimeRange
  alias Airweb.Reader, as: Reader
  alias Airweb.ReaderEntry, as: ReaderEntry
  alias Airweb.Summary, as: Summary
  alias Airweb.SummaryState, as: SummaryState

  @doc ~S"""
  Interprets `input` as a listing of hours spent, outputing a summary accross
  both projects and days.

      iex> "Må 08:15-11:45, Foo\n  12:30-17:00" |> String.splitter("\n") |> Airweb.AirTime.parse()
      {:ok, {2, {[{"Må", 8.0}], [{"Foo", 8.0}], [%{"Foo" => 8.0}], 8.0}}}

      iex> "Må 08:15-11:45, Foo\n\n  12:30-17:00" |> String.splitter("\n") |> Airweb.AirTime.parse()
      {:ok, {3, {[{"Må", 8.0}], [{"Foo", 8.0}], [%{"Foo" => 8.0}], 8.0}}}

  """
  def parse(input) do
    input
    |> Enum.reduce_while({%SummaryState{}, 0}, &reduce_line/2)
    |> Summary.externalize()
  end

  def reduce_line(line, {prev_state, prev_line}) do
    result = Reader.process_line(line)
    {action, state} = handle_reduce_line(prev_state, result)
    {action, {state, prev_line + 1}}
  end

  def build_output({chunk_sums, tag_sums, chunk_tag_sums, week_total}) do
    [
      "",
      build_daily_output(chunk_sums),
      build_week_output(week_total),
      build_tags_output(tag_sums),
      build_chunk_tags_output(chunk_tag_sums)
    ]
    |> Enum.intersperse("\n")
  end

  defp handle_reduce_line(state, {:ok, result}) do
    {:cont, push_entry(state, result)}
  end

  # TODO accept line_num in args and rewrap error
  defp handle_reduce_line(state, error = {:error, _reason}) do
    {:cont, push_error(state, error)}
  end

  defp handle_reduce_line(state, :skip), do: {:cont, state}
  defp handle_reduce_line(state, :halt), do: {:halt, state}

  defp push_entry(s = %SummaryState{}, r = %ReaderEntry{}) do
    {:ok, diff} = parse_time(r.time)
    tag = derive_tag(r.tag, s.latest_tag)
    entry = SummaryState.create_entry(diff, tag, r.chunk, r.type)
    SummaryState.push_entry(s, entry)
  end

  defp parse_time({:interval, i}), do: TimeRange.from_interval(i)
  defp parse_time({:range, r}), do: TimeRange.from_range(r)

  defp derive_tag(:no_tag, latest_tag), do: latest_tag
  defp derive_tag(t, _latest_tag), do: String.trim(t)

  defp push_error(s = %SummaryState{}, {:error, reason}) do
    SummaryState.push_error(s, reason)
  end

  defp build_daily_output(sums), do: ["daily hours: ", inspect(sums)]

  defp build_week_output(total) do
    total_out = inspect(total)
    rem_out = inspect(40 - total)
    ["week total:  ", total_out, " (", rem_out, " remaining)"]
  end

  defp build_tags_output(sums), do: ["tag sum:     \n  ", interspect(sums)]

  defp build_chunk_tags_output(chunk_tag_sums) do
    ["daily tag sums:\n  ", interspect(chunk_tag_sums)]
  end

  defp interspect(enumerable) do
    enumerable
    |> Enum.map(&inspect(&1))
    |> Enum.intersperse("\n  ")
  end
end
