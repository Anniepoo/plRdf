:- module(
  turtle_char,
  [
    'IRIREF'//1, % ?Value:float
    'UCHAR'//1 % ?Code:code
  ]
).
:- reexport(
  sparql_bnode,
  [
    'ANON'//0,
    'BLANK_NODE_LABEL'//0
  ]
).
:- reexport(
  sparql_char,
  [
    'ECHAR'//1,
    'HEX'//1,
    'LANGTAG'//0,
    'PERCENT'//1,
    'PLX'//1,
    'PN_CHARS'//1
  ]
).

/** <module> Turtle character

DCGs for character definitions in Turtle recommendations.

@author Wouter Beek
@version 2014/04-2014/05
*/

:- use_module(dcg(dcg_content)).
:- use_module(math(radix)).



%! 'IRIREF'(?Codes:list(code))// .
% ~~~{.ebfn}
% IRIREF ::= '<' ( [^#x00-#x20<>"{}|^`\] | UCHAR )* '>'
%                  /* #x00=NULL #01, '1F=control codes #x20=space */
% ~~~
%
% @compat Turtle 1.1 [18].

'IRIREF'(L) -->
  bracketed(angular,
    'IRIREF_char*'(L)
  ).

'IRIREF_char*'([H|T]) -->
  'IRIREF_char'(H),
  'IRIREF_char*'(T).
'IRIREF_char*'([]) --> [].

'IRIREF_char'(_) --> [C], {C =< 32}, !, {fail}.
'IRIREF_char'(_) --> "<", !, {fail}.
'IRIREF_char'(_) --> ">", !, {fail}.
'IRIREF_char'(_) --> "\"", !, {fail}.
'IRIREF_char'(_) --> "{", !, {fail}.
'IRIREF_char'(_) --> "}", !, {fail}.
'IRIREF_char'(_) --> "|", !, {fail}.
'IRIREF_char'(_) --> "^", !, {fail}.
'IRIREF_char'(_) --> "\`", !, {fail}.
'IRIREF_char'(_) --> "\\", !, {fail}.
'IRIREF_char'(C) --> 'UCHAR'(C).
'IRIREF_char'(C) --> [C].



%! 'UCHAR'// .
% ~~~{.ebnf}
% UCHAR ::= '\u' HEX HEX HEX HEX | '\U' HEX HEX HEX HEX HEX HEX HEX HEX
% ~~~
%
% @compat Turtle 1.1 [26].

'UCHAR'(C) -->
  "\\u",
  'HEX'(H1), 'HEX'(H2), 'HEX'(H3), 'HEX'(H4),
  {digits_to_decimal([H1,H2,H3,H4], 16, C)}.
'UCHAR'(C) -->
  "\\U",
  'HEX'(H1), 'HEX'(H2), 'HEX'(H3), 'HEX'(H4),
  'HEX'(H5), 'HEX'(H6), 'HEX'(H7), 'HEX'(H8),
  {digits_to_decimal([H1,H2,H3,H4,H5,H6,H7,H8], 16, C)}.

