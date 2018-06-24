defmodule Airweb.Reader do
  require Logger

  # lexing rules
  @chunk_re "(?<chunk>^\\w+)"
  @time_re "(?<time>\\d{2}:\\d{2}(-\\d{2}:\\d{2})?)"
  @tag_re "(?<tag>\\S.*)"
  @tag_separator_re "((,\\s*)|\\s+)"

  @lex_re ~r/(#{@chunk_re}\s+)?(#{@time_re}(,?\s*#{@tag_re})?)$/iu

  @line_chunk_start_re ~r/#{@chunk_re}\s+#{@time_re}#{@tag_separator_re}#{@tag_re}/iu
  @line_chunk_append_re ~r/^\s+#{@time_re}(#{@tag_separator_re}\S.*)?$/iu

  @doc ~S"""
  Parses a timesheet item expected to contain the following parts:

  [chunk-tag] [range-or-interval][[,|\s+]line-tag]

      iex> Airweb.Reader.process_line("Må 08:15-11:45, Bar")
      {:ok, {{:range, ["08:15", "11:45"]}, "Bar", :start, "Må"}}

      iex> Airweb.Reader.process_line("  10:30-14:15")
      {:ok, {{:range, ["10:30", "14:15"]}, "", :append, :no_tag}}

      iex> Airweb.Reader.process_line("  14:00 Foo")
      {:ok, {{:interval, "14:00"}, "Foo", :append, :no_tag}}

  """
  def process_line(dirty_line) do
    Logger.debug(["process_line dirty:", inspect(dirty_line)])
    line = String.trim_trailing(dirty_line)

    Logger.debug(["process_line clean:", inspect(line)])

    with :ok <- check_line_length(line),
         {:ok, line_type} <- check_line_format(line) do
      build_meta(line, line_type)
    else
      :halt -> :halt
      err = {:error, reason} ->
        Logger.warn([
          "Input error: ",
          inspect(reason),
          " (", inspect(dirty_line), ")"
        ])
        err
    end
  end

  # TODO change to :skip and handle downstream
  defp check_line_length(""), do: :halt
  defp check_line_length(_), do: :ok

  defp check_line_format(line) do
    cond do
      line =~ @line_chunk_start_re -> {:ok, :start}
      line =~ @line_chunk_append_re -> {:ok, :append}
      true -> {:error, {:bad_format, line}}
    end
  end

  defp lex_line(line) do
    Regex.named_captures(@lex_re, line)
  end

  defp cannonicalize_line_time(line) do
    case String.split(line, "-") do
      [interval] -> {:interval, interval}
      r = [_start, _stop] -> {:range, r}
    end
  end

  defp build_meta(line, line_type) do
    tokens = lex_line(line)
    time = cannonicalize_line_time(tokens["time"])
    tag = String.trim(tokens["tag"])
    chunk_tag = meta_chunk(tokens)

    {:ok, {time, tag, line_type, chunk_tag}}
  end

  defp meta_chunk(tokens) do
    case Map.get(tokens, "chunk") do
      "" -> :no_tag
      chunk_tag -> chunk_tag |> String.trim()
    end
  end
end
