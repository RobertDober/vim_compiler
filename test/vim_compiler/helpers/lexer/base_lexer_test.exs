defmodule Test.VimCompiler.Helpers.LexerTest do
  use ExUnit.Case

  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]

  describe "names and symbols" do 
    test "names" do 
      tokens = scan("hello world", &filter/1)
      assert tokens == [{:name, 1, "hello"}, {:name, 1, "world"}]
    end
    test "symbols" do 
      tokens = scan(":hello :world", &filter/1)
      assert tokens == [{:symbol, 1, "hello"}, {:symbol, 1, "world"}]
    end
    test "a mix" do 
      tokens = scan(":hello def world :foo", &filter/1)
      assert tokens == [{:symbol, 1, "hello"}, {:kw_def, 1, "def"}, {:name, 1, "world"}, {:symbol, 1, "foo"}]
    end
  end

  describe "tokenize def and defp" do 
    test "one defp" do
      tokens = scan("defp")
      assert hd(tokens) == {:kw_def, 1, "defp"}
    end
    test "one def" do 
      tokens = scan("def")
      assert hd(tokens) == {:kw_def, 1, "def"}
    end
    test "more defs" do 
      tokens = scan("defp\ndefp def", &filter/1)
      assert tokens == [{:kw_def, 1, "defp"}, {:kw_def, 2, "defp"}, {:kw_def, 2, "def"}]
    end
  end

  describe "a definition" do
    test "def" do 
      tokens = scan("def hello world", &filter/1)
      assert tokens == [{:kw_def, 1, "def"}, {:name, 1, "hello"}, {:name, 1, "world"}]
    end
  end

  describe "literals" do
    test "number" do 
      tokens = scan("42", &filter/1)
      assert tokens == [{:lt_number, 1, 42}]
    end
  end

  describe "multiline" do 
    @multi """
      def hello
      42
    """
    test "can be scanned" do 
      tokens = scan(@multi, &filter/1)
      assert tokens == [{:kw_def, 1, "def"}, {:name, 1, "hello"}, {:lt_number, 2, 42}]
    end
  end
  

  defp scan(line, filter \\ fn _ -> false end) do 
    line 
    |> tokenize(with: :lexer)
    |> Enum.reject(filter)
  end

  defp filter({:ws, _, _}), do:  true
  defp filter(_), do:  false
  
end
