defmodule VimCompiler.Parser do
  alias VimCompiler.Ast
  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]

  def parse(str) do
    with tokens <- tokenize(str, with: :lexer) do
      parse_expression(tokens)
    end
  end

  def parse_expression([]) do
    { :ok, %Ast.EOF{}, [] }
  end
  def parse_expression([{:name, _, name}]) do
    {:ok, %Ast.Invocation{fn: name}, []}
  end
  def parse_expression(ts=[{:name, _, _} | [ t1 | rest]]) do
    parse_expression_prime(t1, ts) 
  end
  def parse_expression(tokens), do: parse_term(tokens)

  def parse_expression_prime({:op6,_,_}, tokens), do: parse_term(tokens)
  def parse_expression_prime({:op9,_,_}, tokens), do: parse_factor(tokens)
  def parse_expression_prime(_, [{:name, _, name} | rest]) do
    with {:ok, params, rest1} <- parse_params(rest, []) do
      {:ok, %Ast.Invocation{fn: name, params: params}, rest1}
    end
  end
  
  def parse_params(tokens, params) do
    if end_of_params?(tokens) do
      {:ok, Enum.reverse(params), tokens}
    else
      with {:ok, param, rest} <- parse_primary(tokens), do: parse_params(rest, [param | params])
    end
  end

  def parse_term(tokens) do
    with r = {:ok, lhs, rest} <- parse_factor(tokens) do
      case rest do
        [{:op6, _, op}|rhs] -> parse_term_rhs(rhs, %Ast.Term{lhs: lhs, op: String.to_atom(op)})
        _  -> r
      end
    end
  end
  defp parse_term_rhs(tokens, ast_so_far) do
    with {:ok, rhs, rest} <- parse_term(tokens) do
      {:ok, %{ast_so_far | rhs: rhs}, rest}
    end
  end

  def parse_factor(tokens) do
    with r = {:ok, lhs, rest} <- parse_primary(tokens) do
      case rest do
        [{:op9, _, op}|rhs] -> parse_term_rhs(rhs, %Ast.Factor{lhs: lhs, op: String.to_atom(op)})
        _  -> r
      end
    end
  end

  def parse_primary([{:lt_number, _, number} | rest]) do
    {:ok, %Ast.Number{value: number}, rest}
  end
  def parse_primary([{:name, _, name} | rest]) do
    {:ok, %Ast.Name{text: name}, rest}
  end
  def parse_primary([{:sy_lparen, _, _} | rest]) do
    with {:ok, inner_expression, rest1} <- parse_expression(rest) do
      case rest1 do
        [{:sy_rparen, _, _} | rest2] -> {:ok, inner_expression, rest2}
        _                             -> {:error, "Missing )", rest1}
      end
    end
  end


  defp end_of_params?([]), do: true
  defp end_of_params?([{:sy_rparen, _, _}|_]), do: true
  defp end_of_params?([{:op6, _, _}|_]), do: true
  defp end_of_params?([{:op9, _, _}|_]), do: true
  defp end_of_params?(_), do: false
end
