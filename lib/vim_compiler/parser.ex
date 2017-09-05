defmodule VimCompiler.Parser do
  alias VimCompiler.Ast
  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]

  def parse(str) do
    with tokens <- tokenize(str, with: :lexer) do
      parse_expression(skip_ws(tokens))
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
  def parse_expression(tokens), do: parse_term(skip_ws(tokens))

  def parse_expression_prime({:op6,_,_}, tokens), do: parse_term(skip_ws(tokens))
  def parse_expression_prime({:op9,_,_}, tokens), do: parse_factor(skip_ws(tokens))
  def parse_expression_prime(_, [{:name, _, name} | rest]) do
    with {:ok, params, rest1} <- parse_params(skip_ws(rest), []) do
      {:ok, %Ast.Invocation{fn: name, params: params}, rest1}
    end
  end
  
  def parse_params(tokens, params) do
    if end_of_params?(tokens) do
      {:ok, Enum.reverse(params), tokens}
    else
      with {:ok, param, rest} <- parse_primary(tokens), do: parse_params(skip_ws(rest), [param | params])
    end
  end

  def parse_term(tokens) do
    with r = {:ok, lhs, rest} <- parse_factor(tokens) do
      case rest do
        [{:op6, _, op}|rhs] -> parse_term_rhs(skip_ws(rhs), %Ast.Term{lhs: lhs, op: String.to_atom(op)})
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
        [{:op9, _, op}|rhs] -> parse_term_rhs(skip_ws(rhs), %Ast.Factor{lhs: lhs, op: String.to_atom(op)})
        _  -> r
      end
    end
  end

  def parse_primary([{:lt_number, _, number} | rest]) do
    {:ok, %Ast.Number{value: number}, skip_ws(rest)}
  end
  def parse_primary([{:name, _, name} | rest]) do
    {:ok, %Ast.Name{text: name}, skip_ws(rest)}
  end
  def parse_primary([{:sy_quote, _, _} | rest]) do
    with {:ok, parts, rest1} <- parse_string(rest, []) do
      {:ok, %Ast.String{parts: parts}, skip_ws(rest1)}
    end
  end
  def parse_primary([{:sy_lbrack, _, _} | rest]) do
    with {:ok, elements, rest1} <- parse_list(skip_ws(rest), []) do
      {:ok, %Ast.List{elements: elements}, rest1}
    end
  end
  def parse_primary([{:sy_lparen, _, _} | rest]) do
    with {:ok, inner_expression, rest1} <- parse_expression(skip_ws(rest)) do
      case rest1 do
        [{:sy_rparen, _, _} | rest2] -> {:ok, inner_expression, skip_ws(rest2)}
        _                            -> {:error, "Missing )", rest1}
      end
    end
  end

  def parse_list([{:sy_rbrack,_,_}|rest], result), do: {:ok, Enum.reverse(result), skip_ws(rest)}
  def parse_list(tokens, result) do
    with {:ok, term, rest} <- parse_term(skip_ws(tokens)) do
      case rest do
        [{:sy_rbrack,_,_}|rest1] -> {:ok, Enum.reverse([term|result]), skip_ws(rest1)}
        [{:sy_comma,_,_}|rest1]  -> parse_list(skip_ws(rest1), [term|result])
        _                        -> {:error, "Missing , or ]", rest}
      end
    end
  end

  def parse_string([], result), do: {:ok, compress_result(result, []), []}
  def parse_string([{:sy_quote, _, _} | rest], result), do: {:ok, compress_result(result, []), rest}
  def parse_string([{:escape, _, _}   | rest], result), do: parse_string_prime(rest, result)
  def parse_string([{:sy_hashacc, _, _} | rest], result) do
    with {:ok, expression, rest1} <- parse_expression(rest) do
      case rest1 do
        [{:sy_racc, _, _} | rest2] -> parse_string(rest2, [expression|result])
        _                        -> {:error, "Missing }", rest1}
      end
    end
  end
  def parse_string([{_, _, text} | rest], result) do
    parse_string(rest, [text|result])
  end

  defp parse_string_prime([], result), do: {:ok, compress_result(result, []), []}
  defp parse_string_prime([{_, _, text} | rest], result), do: parse_string(rest, [text | result])

  defp end_of_params?([]), do: true
  defp end_of_params?([{:sy_rparen, _, _}|_]), do: true
  defp end_of_params?([{:sy_racc, _, _}|_]), do: true
  defp end_of_params?([{:op6, _, _}|_]), do: true
  defp end_of_params?([{:op9, _, _}|_]), do: true
  defp end_of_params?(_), do: false

  defp compress_result([], result),                      do: result
  defp compress_result([s|t], result) when is_binary(s), do: compress_result(t, append_str(s, result))
  defp compress_result([e|t], result),                   do: compress_result(t, [e|result])

  defp append_str(s, []),                           do: [s]
  defp append_str(s, [s1|tail]) when is_binary(s1), do: [s <> s1|tail]
  defp append_str(s, tail),                         do: [s|tail]

  defp skip_ws([{:ws,_,_}|tail]), do: skip_ws(tail)
  defp skip_ws(tokens), do: tokens
end
