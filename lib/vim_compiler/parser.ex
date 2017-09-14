defmodule VimCompiler.Parser do
  alias VimCompiler.Ast
  import VimCompiler.Helpers.LeexHelpers, only: [tokenize: 2]

  def parse(str) do
    with tokens <- skip_ws(tokenize(str, with: :lexer)) do
      parse(tokens, %Ast.Tree{})
    end
  end
  def parse([], result_tree) do
    {:ok, Ast.Tree.finalize(result_tree)}
  end
  def parse([{:kw_def, _, deftype}|tokens], result_tree) do
    with {:ok, result_tree1, rest} <- parse_definition(deftype, skip_ws(tokens), result_tree) do
      parse(skip_ws(rest), result_tree1)
    end
  end
  def parse(tokens, result) do
    with {:ok, expression, rest} <- parse_expression(skip_ws(tokens)) do
      parse(skip_ws(rest), [expression|result])
    end
  end

  @doc """
    parses

        (?< defp?) name DefinitionBody
  """
  def parse_definition(deftype, [{:name, _, name}|rest], result_tree) do
    with {:ok, param_patterns, rest1} <- parse_param_patterns(skip_ws(rest), []) do
      # looking at kw_do or sy_assigns here:
       with {:ok, code, rest2} <- parse_definition_body(rest1) do
         {:ok, Ast.Tree.add_definition(result_tree, name, deftype == "defp", param_patterns, code), rest2}
       end
    end
  end
  def parse_definition(deftype, tokens, _) do
    {:error, "Illegal name after #{deftype}", tokens}
  end

  @doc """

    parses

        = Expression

    or

        do
          (Assignment)*   (or +, not sure yet)
        end
  """
  def parse_definition_body([{:sy_assigns,_,_}|body]), do: parse_expression(body)
  def parse_definition_body([{:kw_do,_,_}|body]), do: parse_multi_definition_body(skip_ws(body), [])

  def parse_multi_definition_body(tokens, result) do
    with {:ok, body, rest} <- parse_assignment(tokens), do: parse_multi_definition_body(rest, [body|result])
  end
  def parse_multi_definition_body([{:kw_end,_,_}|rest], result), do: {:ok, Enum.reverse(result), rest}
  def parse_multi_definition_body([], result), do: {:error, "Missing kw end", result}

  @doc """
        (Pattern ("," Pattern)*)?
     with follow: { kw_do, sy_assigns }
     For now: Pattern == Primary
  """
  def parse_param_patterns(tokens = [{:sy_assigns, _, _}|_], result), do: {:ok, Enum.reverse(result), tokens}
  def parse_param_patterns(tokens = [{:kw_do, _, _}|_], result), do: {:ok, Enum.reverse(result), tokens}
  def parse_param_patterns(tokens, result) do
    with {:ok, pattern, rest} <- parse_pattern(tokens), do: parse_param_patterns(skip_ws(rest), [pattern|result])
  end

  @doc """
       Name = Expression | => AssignmentPrime
       Expression
  """
  def parse_assignment(tokens = [{:name, _, name} | tokens1]) do
    case parse_assignment_prime(name, skip_ws(tokens1)) do
      {:ok, _, _ } = t -> t
      :backtrace       -> parse_expression(tokens)
    end
  end
  def parse_assignment(tokens), do: parse_expression(tokens)

  defp parse_assignment_prime(name, [{:sy_assigns, _, _} | tokens]) do
    with {:ok, expression, rest} <- parse_expression(skip_ws(tokens)) do
      {:ok, %Ast.Assignment{name: name, value: expression}, rest}
    end
  end
  defp parse_assignment_prime(_, _), do: :backtrace


  @doc """
  parses:

    Expression ::=
        name op6 Term   | \
        name op9 Factor |  => ExpressionWithName
        name Params     | /
        name            |
        Term; 
  """
  def parse_expression([]) do
    { :ok, %Ast.EOF{}, [] }
  end
  def parse_expression([{:name, _, name}]), do: %Ast.Name{text: name}
  def parse_expression([{:name, _, name}|rest]), do: parse_expression_with_name(name, skip_ws(rest))
  def parse_expression(tokens), do: parse_term(skip_ws(tokens))

  defp parse_expression_with_name(name, [{op6, _, op}|tokens]) do 
    with {:ok, rhs, rest} <- parse_term(skip_ws(tokens)) do
      {:ok, %Ast.Term{lhs: %Ast.Name{text: name}, op: String.to_atom(op), rhs: rhs}, rest}
    end
  end
  defp parse_expression_with_name(name, [{op9, _, op}|tokens]) do 
    with {:ok, rhs, rest} <- parse_factor(skip_ws(tokens)) do
      {:ok, %Ast.Factor{lhs: %Ast.Name{text: name}, op: String.to_atom(op), rhs: rhs}, rest}
    end
  end
  defp parse_expression_with_name(name, tokens) do
    with {:ok, params, rest} <- parse_params(skip_ws(tokens), []) do
      {:ok, %Ast.Invocation{fn: name, params: params}, rest}
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

  # For now:
  def parse_pattern(tokens), do: parse_primary(tokens)

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
