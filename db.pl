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

checkErrorsMacPen([Row|T]) :-
	\+ length(Row, 8) -> assert(invalidPenalty(1))
	; forall(
		(\+ (member(Elem, Row),
		validPenalty(Elem)) 
		-> assert(invalidPenalty(1)))
		),
	checkErrorsMacPen(T).
	
add_tail([],X,[X]).
add_tail([H|T],X,[H|L]):-add_tail(T,X,L).
		
getMacPen([], _).
getMacPen(['too-near penalities'|Tail], _) :- !.
getMacPen([Row1|Tail], MacPen) :- 
	nl, nl, write('getMacPen'), nl, write(Tail),
	atom_chars(Row1, RowPenalty),		% convert to single atoms list for row 1
	delete(RowPenalty, ' ', NewRow),	% delete empty spaces for row 1
	nl, write(NewRow),
	add_tail(MacPen, NewRow, C),
	getMacPen(Tail, C),
	nl,nl,nl, write('Machine penalties 2D:'), nl, write(C).
		
getTooNearHard([]).
getTooNearHard(['machine penalties:'|Tail]) :- 
	getMacPen(Tail, Result).
getTooNearHard([Head|Tail]) :-
	nl, nl, write('getTooNearHard'), nl, write(Tail),
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	nl, write(SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	nl, write(SubSecond),
	assertz(too_near_hard(SubFirst, SubSecond)),
	getTooNearHard(Tail).

getForbidden([]).
getForbidden(['too-near tasks:'|Tail]) :- 
	getTooNearHard(Tail).
getForbidden([Head|Tail]) :-
	nl, nl, write('getForbidden'), nl, write(Tail),
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	nl, write(SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	nl, write(SubSecond),
	assertz(forbidden(SubFirst, SubSecond)),
	getForbidden(Tail).

getForced([]).
getForced(['forbidden machine:'|Tail]) :-
	getForbidden(Tail).
getForced([Head|Tail]) :-
	nl, nl, write('getForced'), nl, write(Tail),
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	nl, write(SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	nl, write(SubSecond),
	assertz(forced(SubFirst, SubSecond)),
	getForced(Tail).
	
parse_lines([]).
parse_lines(['forced partial assignment:'|Tail]) :-
	getForced(Tail).
parse_lines([Head|Tail]) :-
	parse_lines(Tail).

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
	