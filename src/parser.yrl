Nonterminals expression.

Terminals name lt_number.

Rootsymbol expression.

% Expression ::=  ...
expression -> name : [#{text => extract_value('$1'), type => name}].
expression -> lt_number : [#{value => extract_value('$1'), type => number}].

Erlang code.

extract_value({_, _, Text}) -> Text.
