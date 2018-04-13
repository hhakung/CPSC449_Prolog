% Author:
% Date: 4/12/2018
:-include('db.pl').

dynamic(isValidTasks/1).
dynamic(penaltySum/1).

getMachinePenalties([[1,2,1,4,5,6,7,8],[2,1,5,5,6,7,8,9],[1,2,5,6,7,8,9,10],
                   [4,5,6,7,8,9,10,11],[5,6,7,8,9,10,11,12],[6,7,8,9,10,11,12,13],
                   [7,8,9,10,11,12,13,14],[8,9,10,11,12,13,14,15]]).


forbidden('-1', 'A').
%forbidden('1', 'A').
forbidden('0', 'B').

forced('-1','A').
forced('0', 'A').

hardTooNear('Z','Z').
hardTooNear('A','B').

softTooNear('A','C', 10).

% Get element with index (x, y) from machine penalties array
getElement(X, Y, Element) :- getMachinePenalties(Array),
			     taskToInt(Y,Z),
			     nth0(X, Array, Row),
                             nth0(Z, Row, Element).

% Get the index of given element in Array
% Not catching exception yet (empty list)
getIndex(X, Array, Index) :- nth0(Index, Array, X).

assign(Mach, Task, TaskTaken, List) :-
                   (\+ forbidden(Mach, Task)) -> append(TaskTaken, [Task], List).

setForcedForMach(Mach, TaskTaken, List) :-
                          forced(Mach, Task),
                          
                          append(TaskTaken, [Task], List).
                          


intToTask(IntVal, Task) :-
                  ( CharCode is IntVal + 65, (CharCode < 65; CharCode > 72) -> Task = 'Z'
                  ; CharCode is IntVal + 65, char_code(Task, CharCode)).

taskToInt(Task, IntVal) :-
                ( char_code(Task, CharCode), (CharCode < 65; CharCode > 72) -> IntVal is -1
                ; char_code(Task, CharCode), IntVal is CharCode - 65).

% iterate through a list
iterate([], Mach, Combination, ComboArray) :-
    write('end').

iterate([H|T], Mach, Combination, ComboArray) :-
    (forced(Mach, Task) ->
    append(Combination, [Task], NewCombo),
    delete(['A','B','C','D','E','F','G','H'], Task, NewRemainT),
    getCombination(Mach, NewRemainT, NewCombo, ComboArray)),
    (forbidden(Mach, H) -> iterate(T, Mach, Combination, ComboArray)),
    append(Combination, [H], NewCombo),
    getCombination(Mach, ['A','B','C','D','E','F','G','H'], NewCombo, ComboArray),
    iterate(T, Mach, Combination, ComboArray).


getCombination('7',  RemainTask, Combination, ComboArray) :-
    isValid(Combination) ->
    asserta(isValidTasks(Combination)).
    %write(Combination);
    %write('Invalid').

getCombination(Mach , RemainTask, Combination, ComboArray) :-
    atom_number(Mach, M ),
    N is M+1,
    atom_number(X, N),
    iterate(RemainTask, X, Combination, ComboArray).
    
checkTooNearH(7, Combination) :-
    nth0(7, Combination, Element1),
    nth0(0, Combination, Element2),
    \+ hardTooNear(Element1, Element2).

checkTooNearH(Index, Combination) :-
    nth0(Index, Combination, Element1),
    Next is Index + 1,
    nth0(Next, Combination, Element2),
    \+ hardTooNear(Element1, Element2),
    NextIndex is Index + 1,
    checkTooNearH(NextIndex, Combination).
    
isValid(Combination) :-
    is_set(Combination),
    checkTooNearH(0, Combination).

% iterate through a list

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
    too_near_soft(T1,T2,S1),
    too_near_soft(T2,T3,S2),
    too_near_soft(T3,T4,S3),
    too_near_soft(T4,T5,S4),
    too_near_soft(T5,T6,S5),
    too_near_soft(T6,T7,S6),
    too_near_soft(T7,T8,S7),
    too_near_soft(T8,T1,S8),
    Value is C1 + C2 + C3 + C4 + C5 + C6 + C7 + C8 + S1 + S2 + S3 + S4 + S5 +S6 + S7 + S8.


calcPenalty([]).

calcPenalty(Solutions, Penalties) :-
    forall(member(X,Solutions),
	   (getPenalty(X, Penalty),
	    write(Pentalty),
	    append(Penalties, Penalty, Penalties))).

findSol(Sol) :-
    retractall(isValidTasks),
    retractall(penaltySum),
    getCombination('-1', ['A','B','C','D','E','F','G','H'], [], []),
    findall(X, isValidTasks(X), ComboArray),
    calcPenalty(ComboArray),
    findall(Y, penaltySum(Y), PenaltyArray),
    !,
    minLowerBound(PenaltyArray, Index),
    nth0(Index, ComboArray, Sol),
    !.

    
% Get the index of element (first element if there are more than one) with lowest value
% Not catching exception yet (empty list)
minLowerBound(Array, Index) :- min_list(Array, X), getIndex(X, Array, Index).

%new get combinations
checkSol(ASol, 7) :-
   nth0(7, ASol, Task),
   (forced('7', X) ->
   X == Task;
   true).

checkSol(ASol, Index) :-
   NextIndex is Index + 1,
   nth0(Index, ASol, Task),
   atom_number(Mach, Index),
   (forced(Mach, X) ->
   X == Task;
   true),
   checkSol(ASol, NextIndex).





filter([], FilteredC, FilteredC).


filter([H|T], List, FilteredC) :-
    (checkSol(H, 0) ->
    append(List, [H], NewList),
    filter(T, NewList, FilteredC);
    filter(T, List, FilteredC)).

getValidCombo(Combinations) :-
    findall(X, (permutation(['A','B','C','D','E','F', 'G', 'H'],X),
           nth0(0, X, A),
           \+ forbidden('0',A),
	   forced('0', A);\+forced('0',Anything),
           nth0(1, X, B),
           \+ forbidden('1',B),
	   forced('1', B);\+forced('1',Anything),
           nth0(2, X, C),
           \+ forbidden('2',C),
	   forced('2', C);\+forced('2',Anything),
           nth0(3, X, D),
           \+ forbidden('3',D),
	   forced('3', D);\+forced('3',Anything),
           nth0(4, X, E),
           \+ forbidden('4',E),
	   forced('4', E);\+forced('4',Anything),
           nth0(5, X, F),
           \+ forbidden('5',F),
	   forced('5', F);\+forced('5',Anything),
           nth0(6, X, G),
           \+ forbidden('6',G),
	   forced('6', G);\+forced('6',Anything),
           nth0(7, X, H),
           \+ forbidden('7',H),
	   forced('7', H);\+forced('7',Anything),
	   \+ hardTooNear(A,B),
	   \+ hardTooNear(B,C),
	   \+ hardTooNear(C,D),
	   \+ hardTooNear(D,E),
	   \+ hardTooNear(E,F),
	   \+ hardTooNear(F,G),
	   \+ hardTooNear(G,H),
	   \+ hardTooNear(H,A)),
           Combinations),

    %filter(Combinations, [], FilteredC),
    !.


