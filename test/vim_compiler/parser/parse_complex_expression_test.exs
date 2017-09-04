defmodule Test.VimCompiler.Helpers.Parser.ParseComplexExpressionTest do
  use ExUnit.Case

  alias VimCompiler.Ast
  import VimCompiler.Parser, only: [parse: 1]
  
  describe "Infix" do 
    @term """
    2 + 4
    """
    test "term" do 
      {:ok, %Ast.Term{lhs: lhs, rhs: rhs, op: :+}, []} = parse(@term)
      assert lhs == %Ast.Number{value: 2}
      assert rhs == %Ast.Number{value: 4}
    end

    @factor """
      2 * 3 / 4
    """
    test "factor" do
      {:ok, %Ast.Factor{lhs: lhs, rhs: rhs, op: :*}, []} = parse(@factor) 
      %Ast.Factor{lhs: rhs1, rhs: rhs2, op: :/} = rhs 
      assert lhs == %Ast.Number{value: 2}
      assert rhs1 == %Ast.Number{value: 3}
      assert rhs2 == %Ast.Number{value: 4}
    end
  end

  describe "Expressions" do
    @invocation """
    f 1 (g 2)
    """
    test "invocation with invocation" do 
      {:ok, %Ast.Invocation{fn: "f", params: [param1, param2]}, []} = parse(@invocation)
      %Ast.Invocation{fn: "g", params: [subparam]} = param2
      assert param1 == %Ast.Number{value: 1}
      assert subparam == %Ast.Number{value: 2}
    end
  end

  describe "Complex" do 
    @complex """
    f (1 + 2 * 3) g
    """
    test "complex" do
      {:ok,
        %VimCompiler.Ast.Invocation{fn: "f",
           params: params}, []} = parse(@complex)

      [
        %VimCompiler.Ast.Term{lhs: %VimCompiler.Ast.Number{value: 1}, op: :+,
                              rhs: %VimCompiler.Ast.Factor{lhs: %VimCompiler.Ast.Number{value: 2}, op: :*,
                                                           rhs: %VimCompiler.Ast.Number{value: 3}}},
        %VimCompiler.Ast.Name{text: "g"}] = params
    end
  end
end
