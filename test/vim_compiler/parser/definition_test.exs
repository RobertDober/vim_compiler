defmodule VimCompiler.Parser.DefinitionTest do
  use ExUnit.Case
  
  alias VimCompiler.Ast
  import VimCompiler.Parser, only: [parse: 1]
  
  describe "Simple Body" do 
    @simple_definition """
    def x = 42
    """
    test "simple definition" do 
      {:ok, %Ast.Tree{defined_names: ~w(x), env: env}} = parse(@simple_definition)
      %{"x" => definition} = env
      %Ast.Definition{name: "x", private: false, bodies: [body]} = definition
      assert %Ast.Body{patterns: [], code: [%Ast.Number{value: 42}]} == body
    end
  end

end
