dynamic(forced/2).
dynamic(forbidden/2).
dynamic(too_near_hard/2).
dynamic(too_near_soft/3).

dynamic(invalidPenalty/1).
dynamic(invalidForced/1).

	
validPenalty(Num) :-
	integer(Num),
	Num >= 0.
	
validMachine(A) :-
	member(A, [1,2,3,4,5,6,7,8]).
	
validTask(T) :-
	member(T, "ABCDEFGH").
	
% get length of list
len(0, []).
len(L+l, [_|T]) :- len(L, T).
	
% TODO removeNotChar([Char|T], Result) :-
	
% TODO removeSpaces 

parseTooNearSoft([]) :- !.
parseTooNearSoft([A,B,C|Tail]) :-
	forall(
		member(A, [A,B,C|Tail]),
		((validTask(A), validTask(B), validPenalty(C)),
		is_set([A,B,C|Tail])
		-> assert(too_near_soft(A, B, C)),
			parseTooNearSoft(Tail)
			; assert(invalidTask(1)))
	).

getTooNearSoft([Head|Tail]) :-
	\+ sub_string(Head, _, 1, ':')	% if Head does not contain ':'
	-> ( removeNotChar(Head, Result), 
		 append(Result, List, List),
		 getTooNearSoft(Tail),
		 len(I, List),
		 Length is I,
		 (Length mod 2 is 0) -> assert(invalidTooNearSoft(1)) ; parseTooNearSoft(List)
		).

parseTooNearHard([]) :- !.
parseTooNearHard([A,B|Tail]) :-
	forall(
		member(A, [A,B|Tail]),
		((validTask(A), validTask(B)),
		is_set([A,B|Tail])
		-> assert(too_near_hard(A, B)),
			parseTooNearHard(Tail)
			; assert(invalidTask(1)))
	).

getTooNearHard([Head|Tail]) :-
	\+ sub_string(Head, _, 1, ':')	% if Head does not contain ':'
	-> ( removeNotChar(Head, Result), 
		 append(Result, List, List),
		 getTooNearHard(Tail),
		 len(I, List),
		 Length is I,
		 \+ (Length mod 2 is 0) -> assert(invalidTask(1)) ; parseTooNearHard(List)
		).

parseForbidden([]) :- !.
parseForbidden([A,B|Tail]) :-
	forall(
		member(A, [A,B|Tail]),
		((validMachine(A), validTask(B)),
		is_set([A,B|Tail])
		-> assert(forbidden(A, B)),
			parseForbidden(Tail)
			; assert(invalidForbidden(1)))
	).

getForbidden([Head|Tail]) :-
	\+ sub_string(Head, _, 1, ':')	% if Head does not contain ':'
	-> ( removeNotChar(Head, Result), 
		 append(Result, List, List),
		 getForbidden(Tail),
		 len(I, List),
		 Length is I,
		 \+ (Length mod 2 is 0) -> assert(invalidForbidden(1)) ; parseForbidden(List)
		).

checkErrorsMacPen([Row|T]) :-
	\+ length(Row, 8) -> assert(invalidPenalty(1))
	; forall(
		(\+ (member(Elem, Row),
		validPenalty(Elem)) 
		-> assert(invalidPenalty(1)))
		),
	checkErrorsMacPen(T).

getMacPen([H|T], Penalties) :-
	\+ sub_string(H, _, 1, ':')	% if Head does not contain ':'
	-> ( removeSpaces(H, Result), 
		 append(Result, Penalties, Penalties),
		 getMacPen(T, Penalties),
		 \+ length(Penalties, 8) 
		 -> assert(invalidPenalty(1)) 
		 ; checkErrorsMacPen(Penalties)
		).

parseForced([]) :- !.
parseForced([A,B|Tail]) :-
	forall(
		member(A, [A,B|Tail]),
		((validMachine(A), validTask(B)),
		is_set([A,B|Tail])
		-> assert(forced(A, B)),
			parseForced(Tail)
			; assert(invalidForced(1)))
	).

getForced([Head|Tail]) :-
	\+ sub_string(Head, _, 1, ':')	% if Head does not contain ':'
	-> ( removeNotChar(Head, Result), 
		 append(Result, List, List),
		 getForced(Tail),
		 len(I, List), 
		 Length is I,
		 \+ (Length mod 2 is 0) -> assert(invalidForced(1)) ; parseForced(List)
		).
	
	
parse_lines([Line|Tail]) :-
	sub_string(Line, Ind, Len, 'forced partial assignment:') -> getForced(Tail) 
	; sub_string(Line, Ind, Len, 'forbidden machine:') -> getForbidden(Tail) 
	; sub_string(Line, Ind, Len, 'too-near tasks:') -> getTooNearHard(Tail) 
	; sub_string(Line, Ind, Len, 'machine penalties:') -> getMacPen(Tail, []) 
	; sub_string(Line, Ind, Len, 'too-near penalties:') -> getTooNearSoft(Tail) 
	; parse_lines(Tail).


% please help me on this 
read_file(File) :-
        open(File, read, Stream),
 
        % Get list of lines from stream
        % parse_lines(Lines),
		
        close(Stream).