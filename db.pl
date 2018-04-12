dynamic(forced/2).
dynamic(forbidden/2).
dynamic(too_near_hard/2).
dynamic(too_near_soft/3).
dynamic(getMachinePenalties/1).

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

checkErrorsMacPen([Row|T]) :-
	\+ length(Row, 8) -> assert(invalidPenalty(1))
	; forall(
		(\+ (member(Elem, Row),
		validPenalty(Elem)) 
		-> assert(invalidPenalty(1)))
		),
	checkErrorsMacPen(T).
	
getTooNearSoft([]).
getTooNearSoft([Head|Tail]) :-
	nl, nl, write('getTooNearSoft'), nl, write(Tail),
	sub_atom(Head, 1, 5, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	nl, write(SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	nl, write(SubSecond),
	sub_atom(Sub, 4, 1, AfterThird, SubThird),
	nl, write(SubThird),
	assertz(too_near_soft(SubFirst, SubSecond, SubThird)),
	getTooNearSoft(Tail).
	
add_tail([],X,[X]).
add_tail([H|T],X,[H|L]):-add_tail(T,X,L).
		
getMacPen([], _).
getMacPen(['too-near penalities'|Tail], Res) :- 
	assertz(getMachinePenalties(Res)),
	nl, nl, write('Machine penalties 2d: '), nl, write(Res),
	getTooNearSoft(Tail).
getMacPen([Row1|Tail], MacPen) :- 
	nl, nl, write('getMacPen'), nl, write(Tail),
	atom_chars(Row1, RowPenalty),		% convert to single atoms list for row 1
	delete(RowPenalty, ' ', NewRow),	% delete empty spaces for row 1
	nl, write(NewRow),
	add_tail(MacPen, NewRow, C),
	getMacPen(Tail, C).
		
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
	
	% check if there exists the 'too_near_hard' predicate
	(current_predicate(too_near_hard/2)
	-> (too_near_hard(SubSecond, SubFirst) % check if there are constraints that are the reverse
	   -> throw('invalidTooNear')
	   ; (assertz(too_near_hard(SubFirst, SubSecond)),
	     getTooNearHard(Tail)))
	; (assertz(too_near_hard(SubFirst, SubSecond)),
	   getTooNearHard(Tail))
	).

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
	
	% check if there exists the 'forced' predicate
	(current_predicate(forced/2)
	-> ((forced(X, SubSecond) ; forced(SubFirst, Y)) % check if there are duplicating assignments
	   -> throw('partialAssignmentError')
	   ; (assertz(forced(SubFirst, SubSecond)),
	     getForced(Tail)))
	; (assertz(forced(SubFirst, SubSecond)),
	   getForced(Tail))
	).
	
parse_lines([]).
parse_lines(['forced partial assignment:'|Tail]) :-
	getForced(Tail).
parse_lines([Head|Tail]) :-
	parse_lines(Tail).

read_file(File) :-
        catch(open(File, read, InStream), E, (write('Could not open the input file.'), fail)),
        catch(open('output.txt', write, OutStream), E, (write('Could not open the output file.'), fail)),
		read_lines(InStream, Lines),
		
		% remove empty strings from the list
		delete(Lines, '', NewLines1),
		delete(NewLines1, ' ', NewLines2),
		
		write(NewLines2),
		parse_lines(NewLines2),
        close(InStream).
		
read_lines(InStream, []) :-
	at_end_of_stream(InStream).
read_lines(InStream, [Head|Tail]) :-
 	get_code(InStream, Char),
 	checkCharAndReadRest(Char, Chars, InStream),
 	atom_codes(Head, Chars),
	write(Head),
	nl,
	read_lines(InStream, Tail).
	
checkCharAndReadRest(10, [], _) :- !.
checkCharAndReadRest(-1, [], _) :- !.
checkCharAndReadRest(end_of_file, [], _) :- !.

checkCharAndReadRest(Char, [Char|Chars], InStream) :-
	get_code(InStream, NextChar),
	checkCharAndReadRest(NextChar, Chars, InStream).
	