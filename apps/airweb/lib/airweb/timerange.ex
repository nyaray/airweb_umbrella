defmodule Airweb.TimeRange do
  def from_interval(line) do
    from_range ["00:00", "#{line}"]
  end

  def from_range(range=[_s, _e]) do
    with [start_result, end_result] <- parse_range(range),
         {:ok, start_time} <- start_result,
         {:ok, end_time} <- end_result do
      {:ok, hour_diff(start_time, end_time)}
    else
      l when is_list(l) -> {:error, :bad_range}
      e={:error, _reason} ->
        IO.puts "TimeRange.from_diff #{inspect e}:#{inspect range}"
        e
    end
  end

  # internal

  defp parse_range(range) do
    range
    |> Enum.map(&(String.trim/1))
    |> Enum.map(&(&1 <> ":00"))
    |> Enum.map(&(Time.from_iso8601/1))
  end

  defp hour_diff(startTime, endTime) do
    diff = min2hour(time2min(endTime) - time2min(startTime))
    diff + hour_diff_complement(diff)
  end

  defp hour_diff_complement(diff) when diff < 0, do: 24
  defp hour_diff_complement(_diff), do: 0

  defp time2min(x), do: x.hour*60 + x.minute

  defp min2hour(x), do: x/60
end

