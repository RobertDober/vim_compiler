defmodule VimCompiler.Ast do


  # Special Node
  # ============
  defmodule Node do
    @moduledoc """
    A Place Holder Node to collect information is **always** replaced
    in result AST
    """
    defstruct type: :node, children: []
  end

  # Intermediate Nodes
  # ==================
  #   Constructs
  #   ----------
  defmodule Definition do
    @moduledoc """
    Represents a function definition with its name, privacy and all bodies
    """
    defstruct name: "name", private: false, bodies: []
  end
  defmodule Body do
    @moduledoc """
    Represents a definition body with its paramater patterns and the code
    """
    defstruct patterns: [], code: []
  end
  defmodule Assignment do
    @moduledoc """
    An assignment to a name
         <name> = <ast of value>

    name is a string, but value is an Ast.Node
    """
    defstruct name: "the name", value: nil
  end
  defmodule Invocation do
    @moduledoc """
    A Function Invocation represented by the function name and the actual parameters.
    """
    defstruct fn: "a function name", params: [] 
  end

  defmodule Term do
    @moduledoc """
    Represents a term of form lhs (+|- rhs)*
    """
    defstruct lhs: %Node{}, rhs: %Node{}, op: :+
  end

  defmodule Factor do
    @moduledoc """
    Represents a term of form lhs (*|/|// rhs)*
    """
    defstruct lhs: %Node{}, rhs: %Node{}, op: :*
  end

  #   Literals
  #   --------
  defmodule String do
    @moduledoc """
    Represents a list of text and evaluable interpolated expressions
    """
    defstruct parts: []
  end
  defmodule List do
    @moduledoc """
    Represents a list
    """
    defstruct elements: []
  end

  #

  # Leaf Nodes 
  # ==========
  defmodule EOF, do: defstruct dummy: nil
  defmodule Number, do: defstruct value: 0
  defmodule Name, do: defstruct text: ""

  # Top Level
  # =========
  defmodule Tree do
    @moduledoc """
    Top Level AST node, is not present in any child node

    env is a map that maps a defintion's name to all its bodies

        %{"sum" => [%Body{}, ...]}

    defined_names is a list of the names defined in their actual reversed order
    """
    defstruct env: %{}, defined_names: []

    @doc """
    Adds body or creates first entry with that body to definition to env
    """
    def add_definition(tree, name, private, patterns, code) when is_list(code) do
      definition = Map.get(tree.env, name, %VimCompiler.Ast.Definition{name: name, private: private})
      body       =  %Body{patterns: patterns, code: code}
      %{tree |
         env: Map.put(tree.env, name, %{definition | bodies: [body|definition.bodies]}),
         defined_names: [name | tree.defined_names]}
    end
    def add_definition(tree, name, private, patterns, code), do: add_definition(tree, name, private, patterns, [code])

    def finalize(self) do
      %{self | defined_names: Enum.reverse(self.defined_names)}
    end
  end

end
