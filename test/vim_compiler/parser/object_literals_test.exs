defmodule VimCompiler.Parser.ObjectLiteralsTest do
  use ExUnit.Case

  alias VimCompiler.Ast
  import VimCompiler.Parser, only: [parse: 1]
  
  describe "Lists" do 
    test "empty" do 
      assert {:ok, [%Ast.List{elements: []}]} == parse("[]")
    end

    @singleton """
    [ 42 ]
    """
    test "singleton" do
      {:ok, [%Ast.List{elements: [first]}]} = parse(@singleton)
      assert %Ast.Number{value: 42} == first
    end

    @many """
    [ "alpha", 2 + 3, (f 1) ]
    """
    test "many" do
      {:ok, [ %Ast.List{elements: [first, second, third]}]} = parse(@many)

      assert %Ast.String{parts: ["alpha"]} == first
      %Ast.Term{lhs: lhs, rhs: _, op: :+} = second
      assert %Ast.Number{value: 2} == lhs
      %Ast.Invocation{fn: "f", params: _} = third

    end
  end
end
