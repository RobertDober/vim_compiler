defmodule VimCompiler.Helpers.Parser.ParseSimpleExpressionTest do
  use ExUnit.Case

  alias VimCompiler.Ast
  import VimCompiler.Parser, only: [parse_expression: 1]
  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]
  
  describe "Illegal" do 
    test "missing )" do 
      {:error, message, _} = parse("( 42")
      assert message == "Missing )"
    end
  end


  describe "Invocations" do

    @invocation0 """
    f
    """
    test "invocation0" do 
      {:ok, %Ast.Invocation{fn: "f", params: params}, rest} = parse(@invocation0)
      assert params == []
      assert [] == rest
    end

    @invocation1 """
    f 43
    """
    test "invocation1" do 
      {:ok, %Ast.Invocation{fn: "f", params: params}, rest} = parse(@invocation1)
      assert params == [%Ast.Number{value: 43}]
      assert [] == rest
    end

    @invocation2 """
    f 43 44
    """
    test "invocation2" do 
      {:ok, %Ast.Invocation{fn: "f", params: params}, rest} = parse(@invocation2)
      assert params == [%Ast.Number{value: 43}, %Ast.Number{value: 44}]
      assert [] == rest
    end
  end
  defp parse(str) do
    str
      |> tokenize(with: :lexer)
      |> parse_expression()
  end
end
