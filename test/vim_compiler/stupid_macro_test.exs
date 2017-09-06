defmodule VimCompiler.StupidMacroTest do
  use ExUnit.Case
  
  defmodule S do
    use VimCompiler.StupidMacro
    stupid(:xxx)
  end

  test "is 0" do
    assert 0 == S.xxx(0,0)
  end
  test "or not" do
    assert 42 == S.xxx(40,2)
  end
end
