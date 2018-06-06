require Logger

defmodule Airweb.Summary do
  alias Airweb.Entry, as: Entry
  alias Airweb.SummaryState, as: SummaryState

  def new(), do: %SummaryState{}

  def create_entry(diff, tag, chunk_meta) do # TODO diff+tag => entry_meta
    SummaryState.create_entry(diff, tag, chunk_meta)
  end

  def push(s=%SummaryState{}, record) do
    case record do
      e = %Entry{} -> SummaryState.push_entry(s, e)
      {:error, reason} -> SummaryState.push_error(s, reason)
    end
  end

  def externalize(state=%SummaryState{ :errors => errors }) do
    case errors do
      [] -> {:ok, summarize(state)}
      _ -> {:error, Enum.reverse errors}
    end
  end

  defp summarize(state=%SummaryState{}) do
    Logger.debug fn -> "[summarize]\n#{inspect state}" end

    chunk_sums       = SummaryState.sum_chunks state
    tag_sums         = SummaryState.sum_tag_chunks state
    chunk_tag_sums   = SummaryState.get_chunk_tags state
    chunk_tag_totals = Enum.map(chunk_tag_sums, &tally_chunk/1)
    week_total       =
      Enum.reduce chunk_sums, 0, fn ({_chunk_tag, sum}, acc) -> acc + sum end

    # sanity check
    chunk_total = week_total
    tag_total   = tally_tags tag_sums

    ^chunk_total = tag_total
    # TODO check chunk_tag_sums
    ^week_total  = tag_total

    {chunk_sums, tag_sums, chunk_tag_totals, week_total}
  end

  defp tally_tags(tag_sums) do
    Enum.reduce tag_sums, 0,
      fn({_key, sum}, acc) -> sum+acc end
  end

  defp tally_chunk(chunk_tags) do
    Enum.reduce chunk_tags, %{}, fn({key, diffs}, acc) ->
      Map.put acc, key, Enum.sum(diffs)
    end
  end
end

