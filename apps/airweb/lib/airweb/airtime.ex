defmodule Airweb.AirTime do
  require Logger

  alias Airweb.Reader, as: Reader
  alias Airweb.Summary, as: Summary
  alias Airweb.TimeRange, as: TimeRange

  def parse(input) do
    line_provider = String.splitter input, "\n"
    Summary.new
    |> parse_loop(line_provider)
    |> Summary.summarize
    |> output_summary
  end

  defp parse_loop(state, []), do: state
  defp parse_loop(state, line_provider) do
    [ line ] = Enum.take line_provider, 1
    case handle_line(state, line) do
      {:ok, updated_state} ->
        rest = Enum.drop line_provider, 1
        parse_loop updated_state, rest
      :halt ->
        Logger.debug "[parse_loop] done"
        state
    end
  end

  defp handle_line(_state, []), do: :halt
  defp handle_line(_state, :eof), do: :halt
  defp handle_line(state, {:error, reason}) do
    Logger.error ["Input error: ", inspect reason]
    {:ok, state}
  end
  defp handle_line(state, line) do
    Logger.debug ["handle_line ", inspect line]
    case Reader.process_line line, state.latest_tag do
      {:ok, cli_result} ->
        updated_state = handle_cli_result state, line, cli_result
        {:ok, updated_state}
      {:error, reason} ->
        IO.puts ["Input error: ", inspect(reason), " (", inspect(line), ")"]
        {:ok, state}
      :halt ->
        :halt
    end
  end

  defp handle_cli_result(state, line, {time, tag, chunk_start, chunk_tag}) do
    {:ok, diff} = parse_time time
    entry = Summary.create_entry diff, tag, {chunk_start, chunk_tag}
    Logger.debug ["[handle_line] ", inspect(line), " => ", inspect(entry)]
    Summary.push state, entry
  end

  defp parse_time({:interval, i}), do: TimeRange.from_interval i
  defp parse_time({:range, r}), do: TimeRange.from_range r

  defp output_summary(summary) do
    summary
    |> build_output()
  end

  defp build_output({chunk_sums, tag_sums, chunk_tag_sums, week_total}) do
    # TODO factor lines into functions
    ["",
     ["daily hours: ", inspect chunk_sums],
     ["week total:  ", inspect(week_total), " (", inspect(40-week_total), " remaining)"],
     ["tag sum:     \n  ", interspect tag_sums],
     ["daily tag sums:\n  ", interspect chunk_tag_sums]]
    |> Enum.intersperse("\n")
  end

  defp interspect(enumerable) do
    enumerable
    |> Enum.map(&(inspect &1))
    |> Enum.intersperse("\n  ") # TODO factor out @indent
  end
end

