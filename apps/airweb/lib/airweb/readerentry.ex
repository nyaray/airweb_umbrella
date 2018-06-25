defmodule Airweb.ReaderEntry do
  alias Airweb.ReaderEntry, as: ReaderEntry

  require Logger

  defstruct time: "",
            tag: :no_tag,
            chunk: :no_chunk,
            type: :append

  def create_entry(tokens, type) do
    time = tokens["time"] |> cannonicalize_line_time()
    tag = tokens["tag"] |> cannonicalize_line_tag()
    chunk = derive_chunk_fallback(tokens["chunk"], type)
    %ReaderEntry{:time => time, :tag => tag, :chunk => chunk, :type => type}
  end

  defp cannonicalize_line_time(time) do
    case String.split(time, "-") do
      [interval] -> {:interval, interval}
      r = [_start, _stop] -> {:range, r}
    end
  end

  defp cannonicalize_line_tag(tag) do
    case String.trim(tag) do
      "" -> :no_tag
      t -> t
    end
  end

  defp derive_chunk_fallback("", :start), do: :missing
  defp derive_chunk_fallback("", :append), do: :no_chunk
  defp derive_chunk_fallback(chunk, _), do: chunk |> String.trim()
end
