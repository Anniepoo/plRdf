:- module(
  oaei,
  [
    oaei_check_alignment/2, % +ReferenceAlignments:list(pair(iri))
                            % +RawAlignments:list(pair(iri))
    oaei_file_to_alignments/2, % +File:atom
                               % -AlignmentPairs:ordset(pair(iri))
    tsv_convert_directory/4 % +FromDirectory:atom
                            % +ToDirectory:atom
                            % ?ToMIME:atom
                            % -ToFiles:list(atom)
  ]
).

/** <module> OAEI

### OAEI

The Ontology Alignment Evaluation Initiative (OAEI) is a coordinated
international initiative, which organizes the evaluation of the increasing
number of ontology matching systems. The main goal of OAEI is to compare
systems and algorithms on the same basis and to allow anyone to draw
conclusions about the best matching strategies.

### Instance matching

The instance matching track aims at evaluating the performance of different matching
tools on the task of matching RDF individuals which originate from different sources
but describe the same real-world entity. Data interlinking is known under many names
according to various research communities: equivalence mining, record linkage, object
consolidation and coreference resolution to mention the most used ones. In each case,
these terms are used for the task of finding equivalent entities in or across data sets [14].
As the quantity of data sets published on the Web of data dramatically increases, the
need for tools helping to interlink resources becomes more critical. It is particularly
important to maximize the automation of the interlinking process in order to be able to
follow this expansion.

#### Sandbox

The dataset used for the Sandbox task has been automatically generated by extracting
data from Freebase, an open knowledge base that contains information about 11 million
real objects including movies, books, TV shows, celebrities, locations, companies and
more. Data has been extracted in JSON through the Freebase JAVA API. Sandox
is a collection of OWL files consisting of 31 concepts, 36 object properties, 13 data
properties and 375 individuals divided into 10 test cases. In order to provide simple
matching challenges mainly conceived for systems in their initial developing phase,
we limited the way data are transformed from the original Abox to the test cases. In
particular, we introduced only changes in data format (misspelling, errors in text, etc.).

#### IIMB

The IIMB task is focused on two main goals:
    1. to provide an evaluation data set for various kinds of data transformations, including
       value transformations, structural transformations and logical transformations;
    2. to cover a wide spectrum of possible techniques and tools.

ISLab Instance Matching Benchmark (IIMB), that has been generated using the
SWING tool. Participants were requested to find the correct correspondences
among individuals of the first knowledge base and individuals of the other
one. An important task here is that some of the transformations require
automatic reasoning for finding the expected alignments.

IIMB is composed of a set of test cases, each one represented by a set of
instances, i.e., an OWL ABox, built from an initial data set of real linked
data extracted from the Web. Then, the ABox is automatically modified in
several ways by generating a set of new ABoxes, called test cases. Each test
case is produced by transforming the individual descriptions in the
reference ABox in new individual descriptions that are inserted in the test
case at hand. The goal of transforming the original individuals is twofold:
on one side, we provide a simulated situation where data referring to the
same objects are provided in different data sources; on the other side, we
generate different data sets with a variable level of data quality and
complexity. IIMB provides transformation techniques supporting modifications
of data property values, modifications of number and type of properties used
for the individual description, and modifications of the individuals
classification. The first kind of transformations is called *|data value
transformation|* and it aims at simulating the fact that data expressing the
same real object in different data sources may be different because of data
errors or because of the usage of different conventional patterns for data
representation. The second kind of transformations is called *|data structure
transformation|* and it aims at simulating the fact that the same real object
may be described using different properties/attributes in different data
sources. Finally, the third kind of transformations, called *|data semantic
transformation|*, simulates the fact that the same real object may be
classified in different ways in different data sources.

The 2012 edition has been created by exploiting the same OWL source used
for the Sandbox task. The main difference is that we introduced in IIMB
a large set of data transformations. In particular, test cases from 0 to
20 contain changes in data format (misspelling, errors in text, etc);
test cases 21 to 40 contain changes in structure (properties missing,
RDF triples changed); 41 to 60 contain logical changes (class membership
changed, logical errors); finally, test cases 61 to 80 contain a mix of
the previous.

Mismatch types:
    * Data value transformations
    * Data structure transformation
    * Data semantic transformation

@author Wouter Beek
@version 2013/04-2013/05, 2013/08-2013/09, 2013/12-2014/01, 2014/03, 2014/07,
         2014/11
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(csv)).
:- use_module(library(debug)).
:- use_module(library(lists), except([delete/3,subset/2])).
:- use_module(library(ordsets)).
:- use_module(library(semweb/rdf_db), except([rdf_node/1])).
:- use_module(library(semweb/rdfs), except([rdfs_label/3])).
:- use_module(library(uri)).

:- use_module(plc(generics/db_ext)).
:- use_module(plc(generics/meta_ext)).
:- use_module(plc(generics/pair_ext)).
:- use_module(plc(io/dir_ext)).
:- use_module(plc(io/file_ext)).
:- use_module(plc(math/statistics)).
:- use_module(plc(prolog/pl_mode)).

:- use_module(plRdf(rdf_name)).
:- use_module(plRdf(api/rdf_build)).
:- use_module(plRdf(api/rdf_read)).
:- use_module(plRdf(debug/rdf_deb)).
:- use_module(plRdf(graph/rdf_graph_name)).
:- use_module(plRdf(management/rdf_file_db)).
:- use_module(plRdf(management/rdf_load_any)).
:- use_module(plRdf(management/rdf_save_any)).
:- use_module(plRdf(term/rdf_datatype)).
:- use_module(plRdf(term/rdf_literal)).

:- rdf_register_prefix(
  align,
  'http://knowledgeweb.semanticweb.org/heterogeneity/alignment#'
).

:- dynamic(user:prolog_file_type/2).
:- multifile(user:prolog_file_type/2).
:- db_add_novel(user:prolog_file_type(owl, owl)).
:- db_add_novel(user:prolog_file_type(tsv, tsv)).

:- rdf_meta(alignment(r,r,?)).
:- rdf_meta(alignment(r,r,?,?,?)).
:- rdf_meta(assert_alignment(r,r,+)).
:- rdf_meta(assert_alignment(r,r,+,+,+)).

:- db_add_novel(user:file_search_path(alignment2, data(alignment2))).
:- db_add_novel(user:file_search_path(mapping2, alignment2(alignment))).
:- db_add_novel(user:file_search_path(ontology2, alignment2(ontology))).
:- db_add_novel(user:file_search_path(reference2, alignment2(reference))).





%! alignment(?From:iri, ?To:iri, ?Graph:atom) is nondet.

alignment(From, To, Graph):-
  alignment(From, To, =, 1.0, Graph).

%! alignment(
%!   ?From:iri,
%!   ?To:iri,
%!   ?Relation:atom,
%!   ?Measure:between(0.0,1.0),
%!   ?Graph:atom
%! ) is nondet.

alignment(From, To, Relation, Measure, Graph):-
  rdf(BNode, align:entity1, From, Graph),
  rdf(BNode, align:entity2, To, Graph),
  rdf_simple_literal(BNode, align:relation, Relation, Graph),
  rdf_typed_literal(BNode, align:measure, Measure, xsd:float, Graph).


%! alignments_to_oaei_file(+Alignments:list(pair), +File:atom) is det.
% @tbd Is the same alignment allowed to occur multiple times?
%      Otherwise use an ordset i.o. a list.

alignments_to_oaei_file(Alignments, File):-
  setup_call_cleanup(
    rdf_new_graph(Graph),
    (
      forall(
        member(From-To, Alignments),
        assert_alignment(From, To, Graph)
      ),
      rdf_save_any(File, [format(turtle),graph(Graph)])
    ),
    rdf_unload_graph(Graph)
  ).


%! assert_alignment(+Alignment:pair(iri), +Graph:atom) is det.

assert_alignment(From-To, Graph):-
  assert_alignment(From, To, Graph).

%! assert_alignment(+From:iri, +To:iri, +Graph:atom) is det.

assert_alignment(From, To, Graph):-
  assert_alignment(From, To, =, 1.0, Graph).

%! assert_alignment(
%!   +From:iri,
%!   +To:iri,
%!   +Relation:atom,
%!   +Measure:between(0.0,1.0),
%!   +Graph:atom
%! ) is det.

assert_alignment(From, To, Relation, Measure, Graph):-
  rdf_bnode(BNode),
  rdf_assert(BNode, align:entity1, From, Graph),
  rdf_assert(BNode, align:entity2, To, Graph),
  rdf_assert_simple_literal(BNode, align:relation, Relation, Graph),
  rdf_assert_typed_literal(BNode, align:measure, Measure, xsd:float, Graph).


assert_alignments([From-To|Pairs], Graph):- !,
  assert_alignments0([From-To|Pairs], Graph).
assert_alignments(Set, Graph):-
  pair_ext:set_to_pairs(Set, @<, Pairs),
  assert_alignments0(Pairs, Graph).

assert_alignments0(Pairs, Graph):-
  forall(
    member(From-To, Pairs),
    assert_alignment(From, To, Graph)
  ).


%! oaei_check_alignment(
%!   +ReferenceAlignments:list(pair),
%!   +RawAlignments:list(pair)
%! ) is det.
% Tests the quality of a raw alignment relative to the given reference.

oaei_check_alignment(ReferenceAlignments, RawAlignments):-
  t1_error(ReferenceAlignments, RawAlignments, FalsePositives),
  t2_error(ReferenceAlignments, RawAlignments, FalseNegatives),
  ord_intersection(ReferenceAlignments, RawAlignments, X),
  length(X, Overlap),
  % Write the results to user output.
  format(
    user_output,
    '\t~w\t~w\t~w\n',
    [Overlap, FalsePositives, FalseNegatives]
  ),
  flush_output(user_output).


oaei_file_to_alignments(File, Alignments):-
  setup_call_cleanup(
    (
      file_components(File, _, Graph1, _Ext),
      % Make sure the graph name is unique.
      rdf_new_graph(Graph1, Graph2),
      rdf_load_any(File, [graph(Graph2)])
    ),
    oaei_graph_to_alignments(Graph2, Alignments),
    rdf_unload_graph_deb(Graph2)
  ).


%! oaei_graph_to_alignments(+Graph:atom, -Alignments:ordset(pair(iri))) is det.

oaei_graph_to_alignments(Graph, Alignments):-
  % Retrieve all alignment pairs.
  aggregate_all(
    set(From-To),
    alignment(From, To, Graph),
    Alignments
  ).


%! tsv_convert_directory(
%!   +FromDirectory:atom,
%!   +ToDirectory:atom,
%!   ?ToMime:compound,
%!   -ToFiles:list(atom)
%! ) is det.

tsv_convert_directory(FromDir, ToDir, ToMime, ToFiles):-
  default(mime_type(application,'x-turtle',[]), ToMime),
  directory_files(FromDir, FromFiles, [file_types([tsv])]),
  findall(
    ToFile,
    (
      member(FromFile, FromFiles),
      once(rdf_serialization(ToExt, _, ToMime, _)),
      file_alternative(FromFile, ToDir, _, ToExt, ToFile),
      tsv_file_to_oaei_file(FromFile, ToFile)
    ),
    ToFiles
  ).


%! tsv_file_to_alignments(+File:atom, -Alignments:ordset(pair(iri))) is det.
% Opens a tab separated values file and extracts the alignments it contains
% as pairs.

tsv_file_to_alignments(File, Alignments):-
  csv_read_file(File, Rows, [arity(2),separator(9)]),
  aggregate_all(
    set(From-To),
    member(row(From,To), Rows),
    Alignments
  ).


%! tsv_file_to_oaei_file(+FromFile:atom, +ToFile:atom) is det.

tsv_file_to_oaei_file(FromFile, ToFile):-
  tsv_file_to_alignments(FromFile, Alignments),
  alignments_to_oaei_file(Alignments, ToFile).



% TMP %

oaei_graph(Graph):-
  enforce_mode('_oaei_graph'(Graph), [Graph], [['+']-semidet,['-']-nondet]).
'_oaei_graph'(Graph):-
  rdf_graph(Graph),
  once((
    rdfs_individual_of(Alignment, align:'Alignment'),
    rdf(Alignment, _, _, Graph)
  )).


%! oaei_ontologies(+Graph:atom, -File1:atom, -File2:atom) is det.
% Returns the files in which the linked ontologies are stored.

oaei_ontologies(Graph, File1, File2):-
  oaei_ontology(Graph, File1),
  oaei_ontology(Graph, File2),
  File1 \== File2, !.


%! oaei_ontology(+Graph:atom, -File:atom) is nondet.
% Returns an ontology file used in the given alignment graph.

oaei_ontology(Graph, File):-
  rdf_typed_literal(Ontology, align:location, Uri, xsd:anyURI, Graph),
  rdfs_individual_of(Ontology, align:'Ontology'),
  uri_components(Uri, uri_components(_,_,Path,_,_)),
  file_base_name(Path, Base),
  absolute_file_name(ontology2(Base), File, [access(read)]).

