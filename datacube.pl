:- module(
  datacube,
  [
    assert_dataset/3, % +DataStructureDefinition:iri
                      % +Graph:atom
                      % -DataSet:iri
    assert_datastructure_definition/5, % +Dimensions:list(iri)
                                       % +Measures:list(iri)
                                       % +Attributes:list(iri)
                                       % +Graph:atom
                                       % -DataStructureDefinition:iri
    assert_measure_property/4, % +MeasureProperty:iri
                               % +Concept:iri
                               % +Range:iri
                               % +Graph:atom
    assert_multimeasure_observation/5, % +Dataset:iri
                                       % +Property:iri
                                       % :Goal
                                       % +Graph
                                       % -Observation:iri
    assert_observation/5, % +Dataset:iri
                          % +Property:iri
                          % :Goal
                          % +Graph
                          % -Observation:iri
    assert_slice/3 % +DataSet:iri
                   % +Graph:atom
                   % -Slice:iri
  ]
).

/** <module> RDF measurement

Predicates for perfoming measurements represented in RDF.

@author Wouter Beek
@version 2014/09-2014/10
*/

:- use_module(library(lists)).
:- use_module(library(semweb/rdf_db)).

:- use_module(plRdf(rdf_build)).
:- use_module(plRdf(rdf_prefixes)). % RDF prefix declarations.
:- use_module(plRdf_term(rdf_datatype)).
:- use_module(plRdf_term(rdf_dateTime)).

:- use_module(plXsd(xsd)).

:- meta_predicate(assert_observation(+,+,1,+,-)).
:- meta_predicate(assert_multimeasure_observation(+,+,1,+,-)).

:- rdf_meta(assert_dataset(r,+,-)).
:- rdf_meta(assert_datastructure_definition(t,t,t,+,-)).
:- rdf_meta(assert_observation(r,r,:,+,-)).
:- rdf_meta(assert_measure_property(r,r,r,+)).
:- rdf_meta(assert_multimeasure_observation(r,r,:,+,-)).
:- rdf_meta(assert_relation(-,r,+,+)).
:- rdf_meta(assert_relation0(r,+,+,-)).
:- rdf_meta(rdf_assert0(r,r,+,o)).



%! assert_dataset(
%!   +DataStructureDefinition:iri,
%!   +Graph:atom,
%!   -DataSet:iri
%! ) is det.

assert_dataset(DataStructureDefinition, Graph, DataSet):-
  % Create the data set.
  rdf_create_next_resource(data_set, Graph, ['DataSet'], DataSet),

  % rdf:type
  rdf_assert_instance(DataSet, qb:'DataSet', Graph),

  % qb:structure
  rdf_assert(DataSet, qb:structure, DataStructureDefinition, Graph).


%! assert_datastructure_definition(
%!   +Dimensions:list(iri),
%!   +Measures:list(iri),
%!   +Attributes:list(iri),
%!   +Graph:atom,
%!   -DataStructureDefinition:iri
%! ) is det.
% @tbd Add support for qb:order.
% @tbd Add support for qb:componentRequired.
% @tbd Fix RDF expansion in lambda expression.

assert_datastructure_definition(
  Dimensions,
  Measures,
  Attributes,
  Graph,
  DSDef
):-
  % Create the data structure definition resource.
  rdf_create_next_resource(
    data_structure_definition,
    Graph,
    ['DataStructureDefinition'],
    DSDef
  ),
  rdf_assert_instance(DSDef, qb:'DataStructureDefinition', Graph),

  % Create the component resources.
  findall(
    Component,
    (
      member(Dimension, Dimensions),
      assert_relation(Component, qb:dimension, Dimension, Graph)
    ),
    ComponentsA
  ),
  findall(
    Component,
    (
      member(Measure, Measures),
      assert_relation(Component, qb:measure, Measure, Graph)
    ),
    ComponentsB
  ),
  findall(
    Component,
    (
      member(Attribute, Attributes),
      assert_relation(Component, qb:attribute, Attribute, Graph)
    ),
    ComponentsC
  ),
  append([ComponentsA,ComponentsB,ComponentsC], Components),

  % Relate components to data structure definition.
  forall(
    member(Component, Components),
    rdf_assert(DSDef, qb:component, Component, Graph)
  ).


%! assert_measure_property(
%!   +MeasureProperty:iri,
%!   +Concept:iri,
%!   +Range:iri,
%!   +Graph:atom
%! ) is det.

assert_measure_property(MeasureProperty, Concept, Range, Graph):-
  % rdf:type
  rdf_assert_instance(MeasureProperty, qb:'MeasureProperty', Graph),

  % qb:concept
  rdf_assert(MeasureProperty, qb:concept, Concept, Graph),

  % rdfs:range
  rdf_assert(MeasureProperty, rdfs:range, Range, Graph),

  % rdfs:isDefinedBy
  (   rdf_global_id(Prefix:_, MeasureProperty),
      rdf_current_prefix(Prefix, Url)
  ->  rdf_assert(MeasureProperty, rdfs:isDefinedBy, Url, Graph)
  ;   true
  ).


%! assert_multimeasure_observation(
%!   +Dataset:iri,
%!   +Property:iri,
%!   :Goal,
%!   +Graph:atom,
%!   -Observation:iri
%! ) is det.
% Asserts an observation that belongs to a multi-measure dataset.
% This requires the measurement to be specified explicitly.

assert_multimeasure_observation(
  Dataset,
  Property,
  Goal,
  Graph,
  Observation
):-
  assert_observation(Dataset, Property, Goal, Graph, Observation),

  % qb:measureType
  rdf_assert(Observation, qb:measureType, Property, Graph).


%! assert_observation(
%!   +Dataset:iri,
%!   +Property:iri,
%!   :Goal,
%!   +Graph:atom,
%!   -Observation:iri
%! ) is det.

assert_observation(Dataset, Property, Goal, Graph, Observation):-
  % Extract the datatype.
  rdf(Property, rdfs:range, Datatype),
  xsd_datatype(Datatype),

  % Create the observation.
  rdf_create_next_resource(observation, Graph, ['Observation'], Observation),
  rdf_assert_instance(Observation, qb:'Observation', Graph),

  % qb:dataSet
  rdf_assert(Observation, qb:dataSet, Dataset, Graph),

  % Assert the measurement value.
  call(Goal, Value),
  rdf_assert_datatype(Observation, Property, Value, Datatype, Graph),

  % Assert the temporal dimension value.
  rdf_assert_now(Observation, 'sdmx-dimension':timePeriod, Graph).


%! assert_slice(+DataSet:iri, +Graph:atom, -Slice:iri) is det.

assert_slice(DataSet, Graph, Slice):-
  % Create the observation.
  rdf_create_next_resource(slice, Graph, ['Slice'], Slice),

  % rdf:type
  rdf_assert_instance(Slice, qb:'Slice', Graph),

  % qb:slice
  rdf_assert(DataSet, qb:slice, Slice, Graph).



% Helpers

%! assert_relation(
%!   -Component:or([bnode,iri]),
%!   +Relation:iri,
%!   +Dimension:iri,
%!   +Graph:atom
%! ) is det.

assert_relation(Component, Relation, Dimension, Graph):-
  rdf(Component, Relation, Dimension,  Graph), !.
assert_relation(Component, Relation, Dimension, Graph):-
  rdf_bnode(Component),
  rdf_assert(Component, Relation, Dimension, Graph).

