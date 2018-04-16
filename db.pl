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
    write(Stream,MessageStr), 
    close(Stream),
	halt.
	
handleErr(Msg, OutputFile) :-
	write_to_file(OutputFile, Msg).
	
getTooNearSoft([], OutputFile).
getTooNearSoft([Head|Tail], OutputFile) :-
	sub_atom(Head, 1, 5, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	sub_atom(Sub, 4, 1, AfterThird, SubThird),
	catch(
		( (\+ validTask(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidTask')
		; % check if the SubThird is an integer
		catch(
			(atom_to_term(SubThird, Term, Bindings),
			(\+ integer(Term)
			-> throw('invalidPenalty')
			; (atom_number(SubThird, SubThirdNum),
			assertz(too_near_soft(SubFirst, SubSecond, SubThirdNum)),
			getTooNearSoft(Tail, OutputFile)))
			),
			'invalidPenalty',
			handleErr('invalid penalty', OutputFile)
			)
		),
		'invalidTask',
		handleErr('invalid task', OutputFile)
	).
	
add_tail([],X,[X]).
add_tail([H|T],X,[H|L]):-add_tail(T,X,L).

checkColLength([], _).
checkColLength([Head|Tail], OutputFile) :-
	length(Head, ColLength),
	catch(
		(\+ ColLength == 8
		-> throw('machinePenaltyError')
		; checkColLength(Tail, OutputFile)),
		'machinePenaltyError',
		handleErr('machine penalty error', OutputFile)
	).

atomListToNumList(OTail, [], NewL, MacPen, OutputFile) :-
	add_tail(MacPen, NewL, C),
	getMacPen(OTail, C, OutputFile).
atomListToNumList(OTail, [Head|Tail], NewList, MacPen, OutputFile) :-
	atom_number(Head, NumberResult),
	
	% check if the AtomResult is an integer
	atom_to_term(Head, Term, Bindings),
	catch(
		(\+ integer(Term)
		-> throw('invalidPenalty')
		; (add_tail(NewList, NumberResult, C),
		atomListToNumList(OTail, Tail, C, MacPen, OutputFile))),
		'invalidPenalty',
		handleErr('invalid penalty', OutputFile)
	).
		
getMacPen([], _, _).
getMacPen(['too-near penalities'|Tail], Res, OutputFile) :- 
	assertz(getMachinePenalties(Res)),
	length(Res, RowLength),
	catch(
		(\+ RowLength == 8
		-> throw('machinePenaltyError')
		; (checkColLength(Res, OutputFile),
		getTooNearSoft(Tail, OutputFile))),
		'machinePenaltyError',
		handleErr('machine penalty error', OutputFile)
	).
getMacPen([Row1|Tail], MacPen, OutputFile) :- 
	atomic_list_concat(Res, ' ', Row1),
	delete(Res, '', TrimmedRes),
	atomListToNumList(Tail, TrimmedRes, NumList, MacPen, OutputFile).
		
getTooNearHard([], _).
getTooNearHard(['machine penalties:'|Tail], OutputFile) :- 
	getMacPen(Tail, Result, OutputFile).
getTooNearHard([Head|Tail], OutputFile) :-
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),

	catch(
		( (\+ validTask(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidMachineOrTask')
		; % check if there exists the 'too_near_hard' predicate
			(assertz(too_near_hard(SubFirst, SubSecond)),
			getTooNearHard(Tail, OutputFile))
		),
		'invalidMachineOrTask',
		handleErr('invalid machine/task', OutputFile)
	).

checkForbiddenForMachine(9, _).
checkForbiddenForMachine(Machine, OutputFile) :-
	% if the machine is forbidden to select any tasks
	atom_number(MachineChar, Machine),
	findall(Task, forbidden(MachineChar, Task), Result),
	length(Result, Length),
	
	% if the Length is equal to 8, then throw an error.
	catch(
		(Length == 8
		-> throw('invalidForbidden')
		; (NextMachine is Machine + 1, 
		checkForbiddenForMachine(NextMachine, OutputFile))
		),
		'invalidForbidden',
		handleErr('No valid solution possible!', OutputFile)
	).

checkForbiddenForTask([], _).
checkForbiddenForTask([Head|Tail], OutputFile) :-
	% if the Task is forbidden to get selected by any machine
	findall(Machine, forbidden(Machine, Head), Result),
	length(Result, Length),
	
	% if the Length is equal to 8, then throw an error.
	catch(
		(Length == 8
		-> throw('invalidForbidden')
		; checkForbiddenForTask(Tail, OutputFile)
		),
		'invalidForbidden',
		handleErr('No valid solution possible!', OutputFile)
	).
	
getForbidden([], _).
getForbidden(['too-near tasks:'|Tail], OutputFile) :- 
    (current_predicate(forbidden/2)
	-> (checkForbiddenForMachine(1, OutputFile),
		checkForbiddenForTask(['A','B','C','D','E','F','G','H'], OutputFile),
		getTooNearHard(Tail, OutputFile))
	; getTooNearHard(Tail, OutputFile)
	).
getForbidden([Head|Tail], OutputFile) :-
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	catch(
		( (\+ validMachine(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidMachineOrTask')
		; (assertz(forbidden(SubFirst, SubSecond)),
		getForbidden(Tail, OutputFile))
		),
		'invalidMachineOrTask',
		handleErr('invalid machine/task', OutputFile)
	).

getForced([], _).
getForced(['forbidden machine:'|Tail], OutputFile) :-
	getForbidden(Tail, OutputFile).
getForced([Head|Tail], OutputFile) :-
	sub_atom(Head, 1, 3, After, Sub),
	sub_atom(Sub, 0, 1, AfterFirst, SubFirst),
	sub_atom(Sub, 2, 1, AfterSecond, SubSecond),
	catch(
		( (\+ validMachine(SubFirst) ; \+ validTask(SubSecond))
		-> throw('invalidMachineOrTask')
		; % check if there exists the 'forced' predicate
			catch(
				(current_predicate(forced/2)
				-> ((forced(X, SubSecond) ; forced(SubFirst, Y)) % check if there are duplicating assignments
				-> throw('partialAssignmentError')
				; (assertz(forced(SubFirst, SubSecond)),
				getForced(Tail, OutputFile)))
				; (assertz(forced(SubFirst, SubSecond)),
				getForced(Tail, OutputFile))
				),
				'partialAssignmentError',
				handleErr('partial assignment error', OutputFile)
			)
		),
		'invalidMachineOrTask',
		handleErr('invalid machine/task', OutputFile)
	).
	
parse_lines([], _).
parse_lines(['forced partial assignment:'|Tail], OutputFile) :-
	getForced(Tail, OutputFile).
parse_lines([Head|Tail], OutputFile) :-
	parse_lines(Tail, OutputFile).

read_file(File, File2) :-
        catch(open(File, read, InStream), E, (write('Could not open the input file.'), fail)),
		catch(open(File2, write, OutStream), E, (write('Could not open the input file.'), fail)),
		read_lines(InStream, Lines, File2),
		
		% remove empty strings from the list
		delete(Lines, '', NewLines1),
		delete(NewLines1, ' ', NewLines2),
		
		parse_lines(NewLines2, File2),
        close(InStream).
		
read_lines(InStream, [], _) :-
	at_end_of_stream(InStream).
read_lines(InStream, [Head|Tail], OutputFile) :-
 	get_code(InStream, Char),
 	checkCharAndReadRest(Char, Chars, InStream, OutputFile),
 	atom_codes(Head, Chars),
	read_lines(InStream, Tail, OutputFile).
	
checkCharAndReadRest(10, [], _, _) :- !.
checkCharAndReadRest(-1, [], _, _) :- !.
checkCharAndReadRest(35, [], _, OutputFile) :- 
	handleErr('Error while parsing input file', OutputFile).
checkCharAndReadRest(end_of_file, [], _, _) :- !.

checkCharAndReadRest(Char, [Char|Chars], InStream, OutputFile) :-
	get_code(InStream, NextChar),
	checkCharAndReadRest(NextChar, Chars, InStream, OutputFile).
	
