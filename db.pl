dynamic(forced/2).
dynamic(forbidden/2).
dynamic(too_near_hard/2).
dynamic(too_near_soft/3).
dynamic(getMachinePenalties/1).

	
validPenalty(Num) :-
	integer(Num),
	Num >= 0.
	
validMachine(A) :-
	member(A, ['1','2','3','4','5','6','7','8']).
	
validTask(T) :-
	member(T, ['A','B','C','D','E','F','G','H']).
	
% get length of list
len(0, []).
len(L+l, [_|T]) :- len(L, T).

write_to_file(File, Msg) :-
	atom_string(Msg, MessageStr),
	open(File,write,Stream), 
    write(Stream,MessageStr),  nl(Stream), 
    close(Stream),
	abort.
	
handleErr(Msg) :-
	write_to_file('output.txt', Msg).
	
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
	catch(
		( (\+ validTask(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidTask')
		; % check if the SubThird is an integer
		catch(
			(atom_to_term(SubThird, Term, Bindings),
			(\+ integer(Term)
			-> throw('invalidPenalty')
			; (assertz(too_near_soft(SubFirst, SubSecond, SubThird)),
			getTooNearSoft(Tail)))
			),
			'invalidPenalty',
			handleErr('invalid penalty')
			)
		),
		'invalidTask',
		handleErr('invalid task')
	).
	
add_tail([],X,[X]).
add_tail([H|T],X,[H|L]):-add_tail(T,X,L).

checkColLength([]).
checkColLength([Head|Tail]) :-
	length(Head, ColLength),
	catch(
		(\+ ColLength == 8
		-> throw('machinePenaltyError')
		; checkColLength(Tail)),
		'machinePenaltyError',
		handleErr('machine penalty error')
	).

stringListToNumList(OTail, [], NewL, MacPen) :-
	nl, write(NewL),
	add_tail(MacPen, NewL, C),
	getMacPen(OTail, C).
stringListToNumList(OTail, [Head|Tail], NewList, MacPen) :-
	atom_string(AtomResult, Head),
	atom_number(AtomResult, NumberResult),
	
	% check if the AtomResult is an integer
	atom_to_term(AtomResult, Term, Bindings),
	catch(
		(\+ integer(Term)
		-> throw('invalidPenalty')
		; (add_tail(NewList, NumberResult, C),
		stringListToNumList(OTail, Tail, C, MacPen))),
		'invalidPenalty',
		handleErr('invalid penalty')
	).
		
getMacPen([], _).
getMacPen(['too-near penalities'|Tail], Res) :- 
	assertz(getMachinePenalties(Res)),
	nl, nl, write('Machine penalties 2d: '), nl, write(Res),
	length(Res, RowLength),
	catch(
		(\+ RowLength == 8
		-> throw('machinePenaltyError')
		; (checkColLength(Res),
		getTooNearSoft(Tail))),
		'machinePenaltyError',
		handleErr('machine penalty error')
	).
getMacPen([Row1|Tail], MacPen) :- 
	nl, nl, write('getMacPen'), nl, write(Tail),
	atom_string(Row1, S),
	split_string(S, " ", "", Res),
	delete(Res, "", TrimmedRes),
	stringListToNumList(Tail, TrimmedRes, NumList, MacPen).
		
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

	catch(
		( (\+ validTask(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidMachineOrTask')
		; % check if there exists the 'too_near_hard' predicate
			(assertz(too_near_hard(SubFirst, SubSecond)),
			getTooNearHard(Tail))
		),
		'invalidMachineOrTask',
		handleErr('invalid machine/task')
	).

checkForbiddenForMachine(9).
checkForbiddenForMachine(Machine) :-
	% if the machine is forbidden to select any tasks
	atom_number(MachineChar, Machine),
	findall(Task, forbidden(MachineChar, Task), Result),
	length(Result, Length),
	
	% if the Length is equal to 8, then throw an error.
	catch(
		(Length == 8
		-> throw('invalidForbidden')
		; (NextMachine is Machine + 1, 
		checkForbiddenForMachine(NextMachine))
		),
		'invalidForbidden',
		handleErr('No valid solution possible!')
	),
	nl, nl, write('NextMachine is: '), write(NextMachine).

checkForbiddenForTask([]).
checkForbiddenForTask([Head|Tail]) :-
	% if the Task is forbidden to get selected by any machine
	findall(Machine, forbidden(Machine, Head), Result),
	length(Result, Length),
	
	% if the Length is equal to 8, then throw an error.
	catch(
		(Length == 8
		-> throw('invalidForbidden')
		; checkForbiddenForTask(Tail)
		),
		'invalidForbidden',
		handleErr('No valid solution possible!')
	).
	
getForbidden([]).
getForbidden(['too-near tasks:'|Tail]) :- 
    (current_predicate(forbidden/2)
	-> (checkForbiddenForMachine(1),
		checkForbiddenForTask(['A','B','C','D','E','F','G','H']),
		getTooNearHard(Tail))
	; getTooNearHard(Tail)
	).
getForbidden([Head|Tail]) :-
	nl, nl, write('getForbidden'), nl, write(Tail),
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	nl, write(SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	nl, write(SubSecond),
	catch(
		( (\+ validMachine(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidMachineOrTask')
		; (assertz(forbidden(SubFirst, SubSecond)),
		getForbidden(Tail))
		),
		'invalidMachineOrTask',
		handleErr('invalid machine/task')
	).

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
	catch(
		( (\+ validMachine(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidMachineOrTask')
		; % check if there exists the 'forced' predicate
			catch(
				(current_predicate(forced/2)
				-> ((forced(X, SubSecond) ; forced(SubFirst, Y)) % check if there are duplicating assignments
				-> throw('partialAssignmentError')
				; (assertz(forced(SubFirst, SubSecond)),
				getForced(Tail)))
				; (assertz(forced(SubFirst, SubSecond)),
				getForced(Tail))
				),
				'partialAssignmentError',
				handleErr('partial assignment error')
			)
		),
		'invalidMachineOrTask',
		handleErr('invalid machine/task')
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
checkCharAndReadRest(35, [], _) :- 
	handleErr('Error while parsing input file').
checkCharAndReadRest(end_of_file, [], _) :- !.

checkCharAndReadRest(Char, [Char|Chars], InStream) :-
	get_code(InStream, NextChar),
	checkCharAndReadRest(NextChar, Chars, InStream).
	