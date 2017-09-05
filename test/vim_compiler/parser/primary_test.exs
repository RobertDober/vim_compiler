defmodule VimCompiler.Parser.PrimaryTest do
  use ExUnit.Case
  
  alias VimCompiler.Ast
  import VimCompiler.Parser, only: [parse_expression: 1]
  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]
  
  describe "Numbers" do
    @simple1 """
    42
    """
    test "literal 42" do 
      {:ok, %Ast.Number{value: 42}, rest} = parse(@simple1)
      assert [] == rest
    end

    @simple2 """
    ( 42 )
    """
    test "literal (42)" do 
      {:ok, %Ast.Number{value: 42}, rest} = parse(@simple2)
      assert [] == rest
    end
  end

  defp parse(str) do
    str
      |> tokenize(with: :lexer)
      |> parse_expression()
  end
end
