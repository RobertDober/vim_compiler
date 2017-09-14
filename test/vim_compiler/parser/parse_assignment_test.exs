defmodule VimCompiler.Parser.ParseAssignmentTest do
  use ExUnit.Case
  
  alias VimCompiler.Ast
  import VimCompiler.Parser, only: [parse_assignment: 1]
  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]

  describe "any expression is an assignment" do 
    test "literal" do 
      {:ok, %Ast.Number{value: -42}, [{:sy_rparen, _, _}]} = parse("-42 )")
    end

    test "expression" do
      {:ok, %Ast.Factor{lhs: lhs, op: :*, rhs: rhs}, []} = parse("2 * x")
      assert %Ast.Number{value: 2} == lhs
      assert %Ast.Name{text: "x"} == rhs
    end
  end

  describe "but only the presence of an assigns symbol makes an assignment" do
    test "simple assignment" do 
      {:ok, %Ast.Assignment{name: "var", value: value_ast}, []} = parse("var = nil")
      assert %Ast.Name{text: "nil"} == value_ast
    end

    test "complex assignment" do 
      {:ok, %Ast.Assignment{name: "y", value: ast}, []} = parse("y = 2 * x")
      %Ast.Factor{lhs: lhs, op: :*, rhs: rhs} = ast
      assert %Ast.Number{value: 2} == lhs
      assert %Ast.Name{text: "x"} == rhs
    end

    test "invocation vs. var" do
      {:ok, %Ast.Assignment{name: "y", value: ast}, []} = parse("y = x + 2")
      %Ast.Term{lhs: lhs, op: :+, rhs: rhs} = ast
      assert %Ast.Number{value: 2} == rhs
      assert %Ast.Name{text: "x"} == lhs
    end
  end

  defp parse(str) do
    str
      |> tokenize(with: :lexer)
      |> parse_assignment()
  end
  
end
