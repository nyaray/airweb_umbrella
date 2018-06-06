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
    Logger.debug ["process_line dirty:", inspect dirty_line]
    line = String.trim_trailing dirty_line

    Logger.debug ["process_line clean:", inspect line]

    with :ok                <- check_line_length(line),
         :ok                <- check_line_format(line),
         {unsafe_time, tag} <- lex_line(line),
         time               <- cannonicalize_line_time(unsafe_time)
    do
      build_meta(line, time, tag, latest_tag)
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
    [time | maybe_tag] = split_line line
    tag = compute_tag maybe_tag
    {time, tag}
  end

  defp split_line(line) do
    line
    |> String.split(",", [parts: 2])
    |> Enum.map(&String.trim/1)
  end

  defp compute_tag([]), do: :no_tag
  defp compute_tag([tag]), do: tag

  defp cannonicalize_line_time(line) do
    case String.split line, "-" do
      [interval] -> cannonicalize_interval interval
      r=[_s, _e] -> cannonicalize_range r
    end
  end

  defp cannonicalize_interval(interval) do
    {:interval, cannonicalize_time interval}
  end

  defp cannonicalize_range(range) do
    {:range, (for lim <- range, do: cannonicalize_time lim)}
  end

  defp cannonicalize_time(time), do: String.replace(time, ~r/[^0-9:-]/, "")

  defp build_meta(line, safe_time, line_tag, latest_tag) do
    tag         = compute_tag(line_tag, latest_tag)
    chunk_start = compute_chunk_start(line)
    chunk_tag   = compute_chunk_tag(line, chunk_start)
    {:ok, {safe_time, tag, chunk_start, chunk_tag}}
  end

  defp compute_tag(:no_tag, last_tag), do: last_tag
  defp compute_tag(candidate, _last_tag), do: candidate

  defp compute_chunk_start(<< c::utf8, _::binary >>), do: not c in [?\s, ?\t]

  defp compute_chunk_tag(_line, false), do: :no_tag
  defp compute_chunk_tag(line, true) do
    line
    |> String.split(["\s", "\t"], parts: 2, trim: true)
    |> hd()
  end

end

