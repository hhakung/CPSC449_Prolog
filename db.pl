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
	member(T, [A,B,C,D,E,F,G,H]).
	
% get length of list
len(0, []).
len(L+l, [_|T]) :- len(L, T).

% Remove '(', ')', ',' in atom	
removeNotChar( X , Y ) :-
	atom_chars( X , Xs ) ,
	select( '(', Xs , Ys ),
	select(')', Ys, Ys2),
	select(',', Ys2, Ys3),
	select(' ', Ys3, Ys4),
	atom_chars( Y , Ys4).

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
	\+ sub_atom(Head, _, 1, _, ':')	% if Head does not contain ':'
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
	\+ sub_atom(Head, _, 1, _, ':')	% if Head does not contain ':'
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
	\+ sub_atom(Head, _, 1, _, ':')	% if Head does not contain ':'
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
	\+ sub_atom(H, _, 1, _, ':')	% if Head does not contain ':'
	-> ( removeSpaces(H, Result), 
		 append(Result, Penalties, Penalties),
		 getMacPen(T, Penalties),
		 \+ length(Penalties, 8) 
		 -> assert(invalidPenalty(1)) 
		 ; checkErrorsMacPen(Penalties)
		).

getForced(['forbidden machine:'|Tail]) :- !.
getForced([Head|Tail]) :-
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	assertz(forced(SubFirst, SubSecond)),
	getForced(Tail).
	
	
parse_lines([]).
parse_lines([Line|Tail]) :-
	sub_atom(Line, Ind, Len, After, 'forced partial assignment:') -> (nl, nl, write(Tail), getForced(Tail))
	; sub_atom(Line, Ind, Len, After, 'forbidden machine:') -> (nl, nl, write(Tail), getForbidden(Tail))
	; sub_atom(Line, Ind, Len, After, 'too-near tasks:') -> (nl, nl, write(Tail), getTooNearHard(Tail))
	; sub_atom(Line, Ind, Len, After, 'machine penalties:') -> (nl, nl, write(Tail), getMacPen(Tail, [])) 
	; sub_atom(Line, Ind, Len, After, 'too-near penalities:') -> (nl, nl, write(Tail), getTooNearSoft(Tail)) 
	; parse_lines(Tail).


read_file(File) :-
        open(File, read, Stream),
        read_lines(Stream, Lines),
		
		% remove empty strings from the list
		delete(Lines, '', NewLines1),
		delete(NewLines1, ' ', NewLines2),
		
		write(NewLines2),
		parse_lines(NewLines2),
        close(Stream).
		
read_lines(Stream, []) :-
	at_end_of_stream(Stream).
		
 read_lines(Stream, [Head|Tail]) :-
 	get_code(Stream, Char),
 	checkCharAndReadRest(Char, Chars, Stream),
 	atom_codes(Head, Chars),
	write(Head),
	nl,
	read_lines(Stream, Tail).
	
checkCharAndReadRest(10,[],_) :- !.
checkCharAndReadRest(-1,[],_) :- !.
checkCharAndReadRest(end_of_file,[],_) :- !.

checkCharAndReadRest(Char,[Char|Chars],Stream) :-
	get_code(Stream,NextChar),
	checkCharAndReadRest(NextChar,Chars,Stream).