defmodule Test.VimCompiler.Helpers.AllLexerTokensTest do
  use ExUnit.Case

  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]
  #  from a b to {"a", :b},
  # ^i{"ea"ebhhi,lli:A},j
  [
    {"+", :op6},
    {"-", :op6},
    {"*", :op9},
    {"/", :op9},
    {"//", :op9},
    {"defp", :kw_def},
    {"def", :kw_def},
    {"do", :kw_do},
    {"end", :kw_end},
    {"==", :op2},
    {"=", :sy_assigns},
    {"(", :sy_lparen},
    {")", :sy_rparen},
    {"{", :sy_lacc},
    {"}", :sy_racc},
    {"[", :sy_lbrack},
    {"]", :sy_rbrack},
    {32, :lt_number},
    {"hello", :name},
    {"hello'", :name},
    {"do'", :name},
    {"hello''", :name},
    {"\"", :sy_quote},
    {"\\", :escape},
    {" ", :ws},
    {"  ", :ws},
    {" \n ", :ws},
    {"#", :sy_hash},
    {"\#{", :sy_hashacc},

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
