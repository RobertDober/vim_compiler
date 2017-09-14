defmodule VimCompiler.Helpers.LeexHelpers do
  @doc """
    Allows to lex an Elixir string with a leex lexer and returns
    the tokens as needed for a yecc parser.
  """
  def lex text, with: lexer do
    case text
      |> String.to_charlist()
      |> lexer.string() do
        {:ok, tokens, _} -> tokens
      end
  end

  def tokenize line, with: lexer do
    {:ok, tokens, _} =
    line
    |> to_charlist()
    |> lexer.string()
    elixirize_tokens(tokens,[])
    |> compose([])
  end


  defp compose([], result), do: result
  defp compose([{:name, line, name}, {:sy_colon, line, _} | rest], result), do: compose(rest, [{:symbol, line, name}|result])
  defp compose([token|rest], result), do: compose(rest, [token | result])

  defp elixirize_tokens(tokens, rest)
  defp elixirize_tokens([], result), do: result
  defp elixirize_tokens([{token, lnb, text}|rest], result) when is_list(text), do: elixirize_tokens(rest, [{token, lnb, to_string(text)}|result])
  defp elixirize_tokens([{token, lnb, text}|rest], result), do: elixirize_tokens(rest, [{token, lnb, text}|result])

end
