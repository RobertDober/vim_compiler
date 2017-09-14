Definitions.

% Rule from Definition
% ^yyp"dyiwi{ea} : {token, {dguiwea, TokenLine, TokenChars}}.ld$

% Keywords

KW_DEF = defp?
KW_DO  = do
KW_END = end

% Operators

OP_PLUS          = \+
OP_MINUS         = -
OP_MULT          = \*
OP_DIV           = /
OP_DDIV          = //

% Symbols

SY_ASSIGNS = =
SY_EQUALS  = ==
SY_LPAREN  = [(]
SY_RPAREN  = [)]
SY_LACC    = {
SY_RACC    = }
SY_LBRACK  = \[
SY_HASH    = #
SY_HASHACC = #\{
SY_QUOTE   = "
SY_RBRACK  = \]
SY_COMMA   = ,
SY_COLON   = :

ESCAPE   = \\

LETTER   = [a-zA-Z]
INNER_ID = [a-zA-Z_0-9']
NAME     = {LETTER}{INNER_ID}*

DIGIT    = [0-9]
NUMBER   = [-+]?{DIGIT}+


WS       = [\n\s]+
ANY      = [^\s]\\"'()[\s]+

Rules.

{KW_DEF}     : {token, {kw_def, TokenLine, TokenChars}}.
{KW_DO}      : {token, {kw_do, TokenLine, TokenChars}}.
{KW_END}     : {token, {kw_end, TokenLine, TokenChars}}.

{NAME}       : {token, {name, TokenLine, TokenChars}}.

{NUMBER}     : {token, {lt_number, TokenLine, make_number(TokenChars, 0, 1)}}.

{OP_PLUS}    : {token, {op6, TokenLine, TokenChars}}.
{OP_MINUS}   : {token, {op6, TokenLine, TokenChars}}.
{OP_MULT}    : {token, {op9, TokenLine, TokenChars}}.
{OP_DDIV}    : {token, {op9, TokenLine, TokenChars}}.
{OP_DIV}     : {token, {op9, TokenLine, TokenChars}}.

{SY_ASSIGNS} : {token, {sy_assigns, TokenLine, TokenChars}}.
{SY_EQUALS}  : {token, {op2, TokenLine, TokenChars}}.
{SY_LPAREN}  : {token, {sy_lparen, TokenLine, TokenChars}}.
{SY_RPAREN}  : {token, {sy_rparen, TokenLine, TokenChars}}.
{SY_LACC}    : {token, {sy_lacc, TokenLine, TokenChars}}.
{SY_RACC}    : {token, {sy_racc, TokenLine, TokenChars}}.
{SY_LBRACK}  : {token, {sy_lbrack, TokenLine, TokenChars}}.
{SY_RBRACK}  : {token, {sy_rbrack, TokenLine, TokenChars}}.
{SY_HASH}    : {token, {sy_hash, TokenLine, TokenChars}}.
{SY_HASHACC} : {token, {sy_hashacc, TokenLine, TokenChars}}.
{SY_QUOTE}   : {token, {sy_quote, TokenLine, TokenChars}}.
{SY_COMMA}   : {token, {sy_comma, TokenLine, TokenChars}}.
{SY_COLON}   : {token, {sy_colon, TokenLine, TokenChars}}.

{ESCAPE}     : {token, {escape, TokenLine, TokenChars}}.


{WS}         : {token, {ws, TokenLine, TokenChars}}.
{ANY}        : {token, {anything, TokenLine, TokenChars}}.

Erlang code.

make_number([], N, S) -> N * S;
make_number([$+ | Tail], N, _) -> make_number(Tail, N, 1);
make_number([$- | Tail], N, _) -> make_number(Tail, N, -1);
make_number([Head | Tail], N, S)  -> make_number(Tail, 10*N + Head - $0, S).
