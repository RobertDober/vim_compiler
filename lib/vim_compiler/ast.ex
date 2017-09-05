defmodule VimCompiler.Ast do
  
  
  # Top Level
  # =========
  defmodule Tree do
    @moduledoc """
    Top Level AST node, is not present in any child node
    """
    defstruct children: []
  end

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
  defmodule SimpleString, do: defstruct text: ""

  def add_to_children(%{children: children} = node, child) do 
    %{node | children: [child|children]}
  end
end
