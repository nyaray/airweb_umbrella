defmodule Airweb.Reader do
  require Logger

  @doc ~S"""
  Parses a timesheet item expected to contain the following parts:

  - Either a "chunk" tag (e.g. a day) OR some amount of white space
  - Either a time range (e.g. 08:00-10:15) OR a time interval (e.g. 02:15)
  - An (optional) activity tag except for in the beginning of chunks

      iex> Airweb.Reader.process_line("Må 08:15-11:45, Bar", :fallback)
      {:ok, {{:range, ["08:15", "11:45"]}, "Bar", true, "Må"}}

      iex> Airweb.Reader.process_line("  10:30-14:15", :fallback)
      {:ok, {{:range, ["10:30", "14:15"]}, :fallback, false, :no_tag}}

      iex> Airweb.Reader.process_line("14:00", :fallback)
      {:error, {:bad_format, "14:00"}}

  """
  def process_line(dirty_line, latest_tag) do
    Logger.debug(["process_line dirty:", inspect(dirty_line)])
    line = String.trim_trailing(dirty_line)

    Logger.debug(["process_line clean:", inspect(line)])

    with :ok <- check_line_length(line),
         :ok <- check_line_format(line),
         tokens <- lex_line(line),
         time <- cannonicalize_line_time(tokens["time"]) do
      build_meta(line, time, tokens, latest_tag)
    end
  end

  defp check_line_length(""), do: :halt
  defp check_line_length(_), do: :ok

  defp check_line_format(line) do
    cond do
      line =~ ~r/^\w+ +\d{2}:\d{2}(-\d{2}:\d{2})?, \S.*$/iu -> :ok
      line =~ ~r/^ +\d{2}:\d{2}(-\d{2}:\d{2})?(, \S.*)?$/iu -> :ok
      true -> {:error, {:bad_format, line}}
    end
  end

  defp lex_line(line) do
    re = ~r/(?<chunk>^\w+ +)?((?<time>\d{2}:\d{2}(-\d{2}:\d{2})?)(,?\s*(?<tag>\S.*))?)$/iu
    Regex.named_captures(re, line)
  end

  defp cannonicalize_line_time(line) do
    case String.split(line, "-") do
      [interval] -> {:interval, interval}
      r = [_start, _stop] -> {:range, r}
    end
  end

  defp build_meta(line, time, tokens, latest_tag) do
    tag = meta_tag(tokens, latest_tag)
    chunk_start = line =~ ~r/^\S/iu
    chunk_tag = meta_chunk(tokens)

    {:ok, {time, tag, chunk_start, chunk_tag}}
  end

  defp meta_tag(tokens, latest_tag) do
    case Map.get(tokens, "tag") do
      "" -> latest_tag
      t -> t |> String.trim()
    end
  end

  defp meta_chunk(tokens) do
    case Map.get(tokens, "chunk") do
      "" -> :no_tag
      chunk_tag -> chunk_tag |> String.trim()
    end
  end
end
