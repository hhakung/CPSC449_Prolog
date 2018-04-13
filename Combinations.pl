% Author:
% Date: 4/12/2018
:-[db].

dynamic(isValidTasks/1).
dynamic(penaltySum/1).

% Get element with index (x, y) from machine penalties array
getElement(X, Y, Element) :- getMachinePenalties(Array),
			     taskToInt(Y,Z),
			     nth0(X, Array, Row),
                             nth0(Z, Row, Element).
                          
intToTask(IntVal, Task) :-
                  ( CharCode is IntVal + 65, (CharCode < 65; CharCode > 72) -> Task = 'Z'
                  ; CharCode is IntVal + 65, char_code(Task, CharCode)).

taskToInt(Task, IntVal) :-
                ( char_code(Task, CharCode), (CharCode < 65; CharCode > 72) -> IntVal is -1
                ; char_code(Task, CharCode), IntVal is CharCode - 65).

getPenalty(Solution, Value):-
    nth0(0, Solution, T1),
    nth0(1, Solution, T2),
    nth0(2, Solution, T3),
    nth0(3, Solution, T4),
    nth0(4, Solution, T5),
    nth0(5, Solution, T6),
    nth0(6, Solution, T7),
    nth0(7, Solution, T8),
    getElement(0, T1, C1),
    getElement(1, T2, C2),
    getElement(2, T3, C3),
    getElement(3, T4, C4),
    getElement(4, T5, C5),
    getElement(5, T6, C6),
    getElement(6, T7, C7),
    getElement(7, T8, C8),
    (current_predicate(too_near_soft/3)->
	 ((too_near_soft(T1,T2,S1)->S1 is S1;S1 is 0),
	  (too_near_soft(T2,T3,S2)->S2 is S2;S2 is 0),
	  (too_near_soft(T3,T4,S3)->S3 is S3;S3 is 0),
	  (too_near_soft(T4,T5,S4)->S4 is S4;S4 is 0),
	  (too_near_soft(T5,T6,S5)->S5 is S5;S5 is 0),
	  (too_near_soft(T6,T7,S6)->S6 is S6;S6 is 0),
	  (too_near_soft(T7,T8,S7)->S7 is S7;S7 is 0),
	  (too_near_soft(T8,T1,S8)->S8 is S8;S8 is 0),
	  Value is  C1 + C2 + C3 + C4 + C5 + C6 + C7 + C8 + S1 + S2 + S3 + S4 + S5 + S6 + S7 + S8);
    Value is C1 + C2 + C3 + C4 + C5 + C6 + C7 + C8).

calcPenalty([]).
calcPenalty(Solutions, Penalties) :-
    findall(Penalty, (member(X,Solutions), getPenalty(X, Penalty)),Penalties).

main(InputFile):-
    read_file(InputFile),
    getValidCombo(Solutions),
    calcPenalty(Solutions, Penalties),
	open('output.txt', write, Stream),
	length(Penalties, Length),
	(Length == 0
	-> write(Stream, "No valid solution possible!")
	; (min_list(Penalties, Minimum),
	nth0(Index, Penalties, Minimum),
    nth0(Index, Solutions, Solution),
	atomic_list_concat(Solution, ' ', SolutionString),
    write(Stream,"Solution "),
    write(Stream,SolutionString),
    write(Stream, "; Quality: "),
    write(Stream,Minimum))),
	close(Stream),
	halt.

getValidCombo(Combinations) :-
    findall(X, (permutation(['A','B','C','D','E','F', 'G', 'H'],X),
           nth0(0, X, A),
           nth0(1, X, B),
           nth0(2, X, C),
           nth0(3, X, D),
           nth0(4, X, E),
           nth0(5, X, F),
           nth0(6, X, G),
           nth0(7, X, H),
	   (current_predicate(forced/2)->
		(forced('1', A);\+forced('1',Anything)),
		(forced('2', B);\+forced('2',Anything)),
		(forced('3', C);\+forced('3',Anything)),
		(forced('4', D);\+forced('4',Anything)),
		(forced('5', E);\+forced('5',Anything)),
		(forced('6', F);\+forced('6',Anything)),
		(forced('7', G);\+forced('7',Anything)),
		(forced('8', H);\+forced('8',Anything));true),
	   (current_predicate(forbidden/2)->
		(\+ forbidden('1',A)),
		(\+ forbidden('2',B)),
		(\+ forbidden('3',C)),
		(\+ forbidden('4',D)),
		(\+ forbidden('5',E)),
		(\+ forbidden('6',F)),
		(\+ forbidden('7',G)),
		(\+ forbidden('8',H));true),
	   (current_predicate(too_near_hard/2)->
		(\+ too_near_hard(A,B)),
		(\+ too_near_hard(B,C)),
		(\+ too_near_hard(C,D)),
		(\+ too_near_hard(D,E)),
		(\+ too_near_hard(E,F)),
		(\+ too_near_hard(F,G)),
		(\+ too_near_hard(G,H)),
		(\+ too_near_hard(H,A));true)),
            Combinations).


