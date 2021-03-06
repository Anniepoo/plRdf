:- module(rdf_graph_test, []).

/** <module> RDF graph test

Unit testing for RDF graph support.

@author Wouter Beek
@version 2013/10, 2014/01
*/

:- use_module(library(plunit)).



:- begin_tests(rdf_graph).

:- use_module(library(apply)).
:- use_module(library(debug)).
:- use_module(library(semweb/rdf_db), except([rdf_node/1])).

:- use_module(plc(dcg/dcg_content)).
:- use_module(plc(dcg/dcg_generics)).

:- use_module(plRdf(debug/rdf_deb)).
:- use_module(plRdf(term/rdf_term)).





test(rdf_graph_instance, []):-
  maplist(rdf_unload_graph_deb, [test_graph,test_graph_instance]),
  maplist(rdf_bnode, [X1,X2,X3,X4]),
  rdf_assert(X1, rdf:p, X2, test_graph),
  rdf_assert(X3, rdf:p, X4, test_graph),
  rdf_assert(rdf:a, rdf:p, rdf:b, test_graph_instance),
  rdf_assert(rdf:c, rdf:p, rdf:d, test_graph_instance),
  findall(
    Map,
    (
      rdf_graph_instance(test_graph_instance, test_graph, Map),
      dcg_with_output_to(user_output, (list(pl_term, Map), nl))
    ),
    _Maps
  ).

:- end_tests(rdf_graph).

