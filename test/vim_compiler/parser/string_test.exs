defmodule VimCompiler.Parser.StringTest do
  use ExUnit.Case
  
  alias VimCompiler.Ast
  import VimCompiler.Parser, only: [parse: 1]
  
  describe "Strings" do
    @empty """
    ""
    """
    test "empty" do 
      {:ok, %Ast.String{parts: []}, []} = parse(@empty)
    end

    @almost_empty """
    "  "
    """
    test "almost_empty" do
      {:ok, %Ast.String{parts: ["  "]}, []} = parse(@almost_empty)
    end

    @string """
    "hello"
    """
    test "string" do
      {:ok, %Ast.String{parts: ["hello"]}, []} = parse(@string)
    end

    test "escaped" do
      escaped = ~s{"hello \\"world\\""}
      {:ok, %Ast.String{parts: [~s{hello "world"}]}, []} = parse(escaped)
    end

    test "interpolation" do 
      interpolation = ~s{"hello = \\"#} <> "{ 2 + 40}" <> ~s{\\""}
      {:ok, %Ast.String{parts: [p1, p2, p3]}, []} = parse(interpolation)
      assert ~s{hello = "} == p1
      assert ~s{"} == p3

      %Ast.Term{lhs: lhs, rhs: rhs, op: :+} = p2
      assert %Ast.Number{value: 2} == lhs
      assert %Ast.Number{value: 40} == rhs
    end
  end
end
