defmodule Airweb.SummaryState do
  alias Airweb.SummaryState, as: SummaryState
  alias Airweb.Entry, as: Entry

  defstruct chunks: [],
            chunk_tags: [],
            current_chunk: [],
            current_chunk_tags: %{},
            errors: [],
            latest_chunk: :no_chunk,
            latest_tag: :no_tag,
            tag_chunks: %{}

  def create_entry(diff, tag, chunk, type) do
    %Entry{:chunk => chunk, :diff => diff, :tag => tag, :type => type}
  end

  def push_entry(s = %SummaryState{}, e = %Entry{}) do
    s
    |> rotate_chunk(e)
    |> push_chunk_diff(e.diff)
    |> push_tag_diff(e.tag, e.diff)
  end

  def push_error(s = %SummaryState{:errors => errors}, reason) do
    %SummaryState{s | :errors => [reason | errors]}
  end

  def sum_chunks(s = %SummaryState{}) do
    current = Enum.reverse(s.current_chunk)
    chunks = Enum.reverse([{s.latest_chunk, current} | s.chunks])

    Enum.map(
      chunks,
      fn {chunk_tag, diffs} -> {chunk_tag, Enum.sum(diffs)} end
    )
  end

  def sum_tag_chunks(s = %SummaryState{}) do
    Enum.map(s.tag_chunks, fn {tag, chunk} -> {tag, Enum.sum(chunk)} end)
  end

  def get_chunk_tags(s = %SummaryState{}) do
    [s.current_chunk_tags | s.chunk_tags]
    |> Enum.reverse()
  end

  defp rotate_chunk(s = %SummaryState{}, %Entry{:type => :append}), do: s

  defp rotate_chunk(s = %SummaryState{:current_chunk => []}, e = %Entry{:type => :start}) do
    %SummaryState{s | :latest_chunk => e.chunk}
  end

  defp rotate_chunk(s = %SummaryState{:current_chunk => []}, %Entry{:type => :append}) do
    s
  end

  defp rotate_chunk(s = %SummaryState{}, %Entry{:type => :start, :chunk => chunk_tag}) do
    chunk = {s.latest_chunk, Enum.reverse(s.current_chunk)}
    chunks = [chunk | s.chunks]
    chunk_tags = [s.current_chunk_tags | s.chunk_tags]

    %SummaryState{
      s
      | :chunks => chunks,
        :chunk_tags => chunk_tags,
        :current_chunk => [],
        :current_chunk_tags => %{},
        :latest_chunk => chunk_tag
    }
  end

  defp push_chunk_diff(s = %SummaryState{}, diff) do
    %SummaryState{s | :current_chunk => [diff | s.current_chunk]}
  end

  defp push_tag_diff(state, tag, diff) do
    current_chunk_tags = update_tag_chunk(state.current_chunk_tags, tag, diff)
    tag_chunks = update_tag_chunk(state.tag_chunks, tag, diff)

    %SummaryState{
      state
      | :current_chunk_tags => current_chunk_tags,
        :latest_tag => tag,
        :tag_chunks => tag_chunks
    }
  end

  defp update_tag_chunk(tag_chunks, latest_tag, diff) do
    tag_chunk = Map.get(tag_chunks, latest_tag, [])
    Map.put(tag_chunks, latest_tag, [diff | tag_chunk])
  end
end
