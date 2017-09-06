defmodule VimCompiler.StupidMacro do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end
  defmacro stupid(name) do
    quote do
    def unquote(name)(0, r), do: r
    def unquote(name)(m, r), do: unquote(name)(m-1, r+1)
    end
  end
end
