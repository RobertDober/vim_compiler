defmodule Test.VimCompiler.Helpers.AllLexerTokensTest do
  use ExUnit.Case

  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]

  [
    {"+", :op6},
    {"-", :op6},
    {"*", :op9},
    {"/", :op9},
    {"//", :op9},
    {"defp", :kw_def},
    {"def", :kw_def},
    {"==", :op2},
    {"=", :sy_assigns},
    {"(", :sy_lparen},
    {")", :sy_rparen},
    {"{", :sy_lacc},
    {"}", :sy_racc},
    {"[", :sy_lbrack},
    {"]", :sy_rbrack},
    {32, :lt_number},
    {"hello", :name}

  ] |> Enum.each( fn {str, token} ->
   test( "#{token} for " <> inspect(str) ) do
     {scanned_tk, _, scanned_text} = scan1(unquote(str))
     assert {scanned_tk, scanned_text} == {unquote(token), unquote(str)}
   end
  end)
  defp scan1(line) do 
  line 
  |> tokenize(with: :lexer)
  |> hd()
  end
end
