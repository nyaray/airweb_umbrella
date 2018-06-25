require Logger

defmodule Airweb.Summary do
  alias Airweb.SummaryState, as: SummaryState
  alias Airweb.TimeRange, as: TimeRange
  alias Airweb.ReaderEntry, as: ReaderEntry

  def new(), do: %SummaryState{}

  def push_entry(s = %SummaryState{}, r = %ReaderEntry{}) do
    {:ok, diff} = parse_time(r.time)
    tag = derive_tag(r.tag, s.latest_tag)
    entry = SummaryState.create_entry(diff, tag, r.chunk, r.type)
    SummaryState.push_entry(s, entry)
  end

  def push_error(s = %SummaryState{}, {:error, reason}) do
    SummaryState.push_error(s, reason)
  end

  def externalize({state = %SummaryState{:errors => errors}, num_lines}) do
    case errors do
      [] -> {:ok, {num_lines, summarize(state)}}
      _ -> {:error, {num_lines, Enum.reverse(errors)}}
    end
  end

  defp parse_time({:interval, i}), do: TimeRange.from_interval(i)
  defp parse_time({:range, r}), do: TimeRange.from_range(r)

  defp derive_tag(:no_tag, latest_tag), do: latest_tag
  defp derive_tag(t, _latest_tag), do: String.trim(t)

  # TODO create struct for result marshalling
  defp summarize(state = %SummaryState{}) do
    Logger.debug(fn -> "[summarize]\n#{inspect(state)}" end)

    chunk_sums = SummaryState.sum_chunks(state)
    tag_sums = SummaryState.sum_tag_chunks(state)
    chunk_tag_sums = SummaryState.get_chunk_tags(state)
    chunk_tag_totals = Enum.map(chunk_tag_sums, &tally_chunk/1)
    week_total = Enum.reduce(chunk_sums, 0, fn {_chunk_tag, sum}, acc -> acc + sum end)

    # sanity check
    chunk_total = week_total
    tag_total = tally_tags(tag_sums)

    ^chunk_total = tag_total
    # TODO check chunk_tag_sums
    ^week_total = tag_total

    # TODO struct me, plz
    {chunk_sums, tag_sums, chunk_tag_totals, week_total}
  end

  defp tally_tags(tag_sums) do
    Enum.reduce(tag_sums, 0, fn {_key, sum}, acc -> sum + acc end)
  end

  defp tally_chunk(chunk_tags) do
    Enum.reduce(chunk_tags, %{}, fn {key, diffs}, acc ->
      Map.put(acc, key, Enum.sum(diffs))
    end)
  end
end
