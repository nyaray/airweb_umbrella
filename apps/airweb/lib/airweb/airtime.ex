defmodule Airweb.AirTime do
  require Logger

  alias Airweb.Reader, as: Reader
  alias Airweb.Summary, as: Summary
  alias Airweb.TimeRange, as: TimeRange

  @doc ~S"""
  Interprets `input` as a listing of hours spent, outputing a summary accross
  both projects and days.

      iex> "Må 08:15-11:45, Foo\n  12:30-17:00\n" |> String.splitter("\n") |> Airweb.AirTime.parse()
      {:ok, {[{"Må", 8.0}], [{"Foo", 8.0}], [%{"Foo" => 8.0}], 8.0}}

  """
  def parse(input) do
    input
    |> Enum.reduce_while(Summary.new(), &reduce_line/2)
    |> Summary.externalize()
  end

  def parse(input, state) do
    input
    |> Enum.reduce_while(state, &reduce_line/2)
    |> Summary.externalize()
  end

  def reduce_line(line, state) do
    case Reader.process_line(line) do
      {:ok, result} ->
        {:cont, handle_line_result(state, line, result)}

      error = {:error, reason} ->
        Logger.warn(["Input error: ", inspect(reason), " (", inspect(line), ")"])
        {:cont, Summary.push(state, error)}

      :halt ->
        Logger.debug("[reduce_line] halt")
        {:halt, state}
    end
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

  defp handle_line_result(state, line, {time, tag, line_type, chunk_tag}) do
    {:ok, diff} = parse_time(time)
    tag = derive_tag(tag, state.latest_tag)
    entry = Summary.create_entry(diff, tag, {line_type, chunk_tag})
    Logger.debug(["[handle_line] ", inspect(line), " => ", inspect(entry)])
    Summary.push(state, entry)
  end

  defp parse_time({:interval, i}), do: TimeRange.from_interval(i)
  defp parse_time({:range, r}), do: TimeRange.from_range(r)

  defp derive_tag(current_tag, latest_tag) do
    case current_tag do
      "" -> latest_tag
      t -> String.trim(t)
    end
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
