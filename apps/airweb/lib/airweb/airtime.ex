defmodule Airweb.AirTime do
  require Logger

  alias Airweb.Reader, as: Reader
  alias Airweb.Summary, as: Summary

  @doc ~S"""
  Interprets `input` as a listing of hours spent, outputing a summary accross
  both projects and days.

      iex> "Må 08:15-11:45, Foo\n  12:30-17:00" |> String.splitter("\n") |> Airweb.AirTime.parse()
      {:ok, {2, {[{"Må", 8.0}], [{"Foo", 8.0}], [%{"Foo" => 8.0}], 8.0}}}

  """
  def parse(input) do
    input
    |> Enum.reduce_while({Summary.new(), 0}, &reduce_line/2)
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
    {:cont, Summary.push_entry(state, result)}
  end

  # TODO accept line_num in args and rewrap error
  defp handle_reduce_line(state, error = {:error, reason}) do
    {:cont, Summary.push_error(state, error)}
  end

  defp handle_reduce_line(state, :halt) do
    {:halt, state}
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
