:- module(
  uri_hier,
  [
    'hier-part'//4, % ?Iri:boolean
                    % ?Scheme:atom
                    % ?Authority:compound
                    % ?Segments:list(atom)
    'path-abempty'//2, % ?Iri:boolean
                       % ?Segments:list(atom)
    'path-absolute'//2, % ?Iri:boolean
                        % ?Segments:list(atom)
    'path-empty'//2, % ?Iri:boolean
                     % ?Segments:list(atom)
    'path-noscheme'//2, % ?Iri:boolean
                        % ?Segments:list(atom)
    segment//2 % ?Iri:boolean
               % ?Segment:atom
  ]
).

/** <module> URI Syntax: Hierarchical part

Grammar for URI hierarchical parts.

@author Wouter Beek
@compat RFC 3987
@see http://tools.ietf.org/html/rfc3987
@version 2015/08
*/

:- use_module(library(dcg/dcg_abnf)).
:- use_module(library(dcg/dcg_ascii)).
:- use_module(library(dcg/dcg_word)).
:- use_module(library(uri/uri_authority)).
:- use_module(library(uri/uri_char)).





%! forwardslash_segment(?Iri:boolean, ?Segment:atom)// .
% Slight abbreviation for a construct that occurs in a lot of rules.

forwardslash_segment(I, Segment) -->
  "/",
  segment(I, Segment).



%! 'hier-part'(
%!   ?Iri:boolean,
%!   ?Scheme:atom,
%!   ?Authority:compound,
%!   ?Segments:list(atom)
%! )// .
% IRI-2: IRI hierarchical part.
%
% ```abnf
%  hier-part =   "//" authority path-abempty
%              / path-absolute
%              / path-rootless
%              / path-empty
% ihier-part =   "//" iauthority ipath-abempty
%              / ipath-absolute
%              / ipath-rootless
%              / ipath-empty
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'hier-part'(I, Scheme, Auth, Segments) -->
  "//",
  authority(I, Scheme, Auth),
  'path-abempty'(I, Segments).
'hier-part'(I, _, _, Segments) -->
  'path-absolute'(I, Segments).
'hier-part'(I, _, _, Segments) -->
  'path-rootless'(I, Segments).
'hier-part'(I, _, _, Segments) -->
  'path-empty'(I, Segments).



%! path(?Iri:boolean, ?Segments:list(atom))// .
% ```abnf
%  path =    path-abempty    ; begins with "/" or is empty
%         /  path-absolute   ; begins with "/" but not "//"
%         /  path-noscheme   ; begins with a non-colon segment
%         /  path-rootless   ; begins with a segment
%         /  path-empty      ; zero characters
% ipath =   ipath-abempty    ; begins with "/" or is empty
%         / ipath-absolute   ; begins with "/" but not "//"
%         / ipath-noscheme   ; begins with a non-colon segment
%         / ipath-rootless   ; begins with a segment
%         / ipath-empty      ; zero characters
% ```
%
% @compat RFC 3986
% @compat RFC 3987

% Begins with "/" or is empty.
path(I, Segments) --> 'path-abempty'(I, Segments).
% Begins with "/" but not "//".
path(I, Segments) --> 'path-absolute'(I, Segments).
% Begins with a non-colon segment
path(I, Segments) --> 'path-noscheme'(I, Segments).
% Begins with a segment
path(I, Segments) --> 'path-rootless'(I, Segments).
% Empty path (i.e., no segments).
path(I, Segments) --> 'path-empty'(I, Segments).



%! 'path-abempty'(?Iri:boolean, ?Segments:list(atom))// .
% ```abnf
%  path-abempty = *( "/"  segment )
% ipath-abempty = *( "/" isegment )
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'path-abempty'(Iri, Segments) -->
  *(forwardslash_segment(Iri), Segments, []).



%! 'path-absolute'(?Iri:boolean, ?Segments:list(atom))// .
% ```abnf
%  path-absolute = "/" [  segment-nz *( "/"  segment ) ]
% ipath-absolute = "/" [ isegment-nz *( "/" isegment ) ]
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'path-absolute'(I, Segments) -->
  "/",
  (   'segment-nz'(I, H),
      *(forwardslash_segment(I), T, []),
      {Segments = [H|T]}
  ;   {Segments = []}
  ).



%! 'path-empty'(?Iri:boolean, ?Segments:list(atom))// .
% ```abnf
%  path-empty = 0< pchar>
% ipath-empty = 0<ipchar>
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'path-empty'(_, []) --> [].



%! 'path-noscheme'(?Iri:boolean, ?Segments:list(atom))// .
% ```abnf
%  path-noscheme =  segment-nz-nc *( "/"  segment )
% ipath-noscheme = isegment-nz-nc *( "/" isegment )
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'path-noscheme'(I, [H|T]) -->
  'segment-nz-nc'(I, H),
  *(forwardslash_segment(I), T, []).



%! 'path-rootless'(?Iri:boolean, ?Segments:list(atom))// .
% ```abnf
%  path-rootless =  segment-nz *( "/"  segment )
% ipath-rootless = isegment-nz *( "/" isegment )
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'path-rootless'(I, [H|T]) -->
  'segment-nz'(I, H),
   *(forwardslash_segment(I), T, []).



%! segment(?Iri:boolean, ?Segment:atom)// .
% ```abnf
%  segment = * pchar
% isegment = *ipchar
% ```
%
% @compat RFC 3986
% @compat RFC 3987

segment(I, Segment) -->
  *(pchar(I), Cs, []),
  {atom_codes(Segment, Cs)}.



%! 'segment-nz'(?Iri:boolean, ?Segment:atom)// .
% Non-empty (nz = non-zero?) segment.
%
% ```abnf
%  segment-nz = 1* pchar
% isegment-nz = 1*ipchar
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'segment-nz'(I, Segment) -->
  '+'(pchar(I), Cs, []),
  {atom_codes(Segment, Cs)}.



%! 'segment-nz-nc'(?Iri:boolean, ?Segment:atom)// .
% Non-zero-length segment without any colon.
%
% ```abnf
%  segment-nz-nc = 1*(  unreserved / pct-encoded / sub-delims / "@" )
% isegment-nz-nc = 1*( iunreserved / pct-encoded / sub-delims / "@" )
%                ; non-zero-length segment without any colon ":"
% ```
%
% @compat RFC 3986
% @compat RFC 3987

'segment-nz-nc'(I, Segment) -->
  dcg_atom('segment-nz-nc_codes'(I), Segment).

'segment-nz-nc_codes'(I, [H|T]) -->
  (   unreserved(I, H)
  ;   'pct-encoded'(H)
  ;   'sub-delims'(H)
  ;   at_sign(H)
  ),
  'segment-nz-nc_codes'(I, T).
'segment-nz-nc_codes'(_, []) --> "".
