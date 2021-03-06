:- module(
  sw_term,
  [
    graphLabel//1, % ?Graph:atom
    object//1, % ?Object:rdf_term
    predicate//1, % ?Predicate:iri
    subject//1 % ?Subject:or([bnode,iri])
  ]
).

/** <module> SW: Terms

Various grammar rules for SW terms.

@author Wouter Beek
@version 2014/12-2015/02
*/

:- use_module(plRdf(syntax/sw_bnode)).
:- use_module(plRdf(syntax/sw_iri)).
:- use_module(plRdf(syntax/sw_literal)).





%! graphLabel(?Graph:atom)// .
% ```abnf
% graphLabel ::= IRIREF | BLANK_NODE_LABEL
% ```
%
% @compat N-Quads 1.1 [6]

graphLabel(Iri) -->
  'IRIREF'(Iri).
graphLabel(BNode) -->
  'BLANK_NODE_LABEL'(n, BNode).



%! object(?Object:rdf_term)// .
% ```abnf
% object ::= IRIREF | BLANK_NODE_LABEL | literal
% ```
%
% @compat N-Quads 1.1 [5].
% @compat N-Triples 1.1 [5].

object(Iri) -->
  'IRIREF'(Iri).
object(BNode) -->
  'BLANK_NODE_LABEL'(n, BNode).
object(Literal) -->
  literal(n, Literal).



%! predicate(?Predicate:iri)// .
% ```abnf
% predicate ::= IRIREF
% ```
%
% @compat N-Quads 1.1 [4].
% @compat N-Triples 1.1 [4].

predicate(Iri) -->
  'IRIREF'(Iri).



%! subject(?Subject:or([bnode,iri])) .
% ```abnf
% subject ::= IRIREF | BLANK_NODE_LABEL
% ```
%
% @compat N-Quads 1.1 [3].
% @compat N-Triples 1.1 [3].

subject(Iri) -->
  'IRIREF'(Iri).
subject(BNode) -->
  'BLANK_NODE_LABEL'(n, BNode).

