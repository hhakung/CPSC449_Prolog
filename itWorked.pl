% Author:
% Date: 4/12/2018

dynamic(isValidTasks/1).
dynamic(penaltySum/1).

getMachinePenalties([[10,2,0,0,20,30,40,50],[2,1,5,5,6,7,8,9],[1,2,5,6,7,8,9,10],
                   [4,5,6,7,8,9,10,11],[5,6,7,8,200,10,11,12],[70,7,40,9,10,20,12,100],
                   [7,8,9,10,11,12,13,14],[100,60,10,50,40,30,14,0]]).


forbidden('-1', 'A').
%forbidden('0', 'A').
%forbidden('0', 'B').
%forbidden('0', 'B').

forced('-1','A').
forced('0','A').
forced('0','B').
forced('2','C').
forced('3','D').
forced('4','E').
forced('5','F').
forced('6','G').
forced('7','H').

hardTooNear('Z','Z').
%hardTooNear('A','B').

softTooNear('A','C', 10).

% Get element with index (x, y) from machine penalties array
getElement(X, Y, Element) :- getMachinePenalties(Array),nth0(X, Array, Row),
                                    nth0(Y, Row, Element).

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

getPenalty(Tasks, 7, Penalty, TotalPenalty) :-
    nth0(7, Tasks, Task),
    taskToInt(Task, IntTask),
    getElement(7, IntTask, Num),
    nth0(7, Tasks, Element1),
    nth0(0, Tasks, Element2),
    (softTooNear(Element1, Element2, SoftPenalty) ->
    TotalPenalty is (Penalty + Num + SoftPenalty);
    TotalPenalty is (Penalty + Num)).

getPenalty(Tasks, Index, Penalty, TotalPenalty) :-
    NextIndex is (Index + 1),
    nth0(Index, Tasks, Task),
    taskToInt(Task, IntTask),
    getElement(Index, IntTask, Num),
    nth0(Index, Tasks, Element1),
    Next is Index + 1,
    nth0(Next, Tasks, Element2),
    (softTooNear(Element1, Element2, SoftPenalty)->
    AddPenalty is (Penalty + Num + SoftPenalty),
    getPenalty(Tasks, NextIndex, AddPenalty, TotalPenalty);
    AddPenalty is (Penalty + Num),
    getPenalty(Tasks, NextIndex, AddPenalty, TotalPenalty)).

calcPenalty([]).

calcPenalty([H|T]) :-
    getPenalty(H, 0, 0, Penalty),
    assertz(penaltySum(Penalty)),
    calcPenalty(T).
    
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

checkSol(ASol, 7) :-
   nth0(7, ASol, Task),
   (forced('7', X) ->
   X == Task;
   true),
   nth0(7, ASol, Element1),
   nth0(0, ASol, Element2),
   \+ hardTooNear(Element1, Element2).

checkSol(ASol, Index) :-
   NextIndex is Index + 1,
   nth0(Index, ASol, Task),
   atom_number(Mach, Index),
   (forced(Mach, X) ->
   X == Task;
   true),
   nth0(Index, ASol, Element1),
   nth0(NextIndex, ASol, Element2),
   \+ hardTooNear(Element1, Element2),
   checkSol(ASol, NextIndex).

addPenalty(Tasks, 7, Penalty, Min, TotalPenalty) :-
    nth0(7, Tasks, Element1),
    taskToInt(Element1, IntTask),
    getElement(7, IntTask, Num),
    nth0(0, Tasks, Element2),
    (softTooNear(Element1, Element2, SoftPenalty) ->
    TotalPenalty is (Penalty + Num + SoftPenalty);
    TotalPenalty is (Penalty + Num)).
    
addPenalty(Tasks, Index, Penalty, Min, TotalPenalty) :-
 NextIndex is (Index + 1),
    nth0(Index, Tasks, Element1),
    taskToInt(Element1, IntTask),
    getElement(Index, IntTask, Num),
    nth0(NextIndex, Tasks, Element2),
    (softTooNear(Element1, Element2, SoftPenalty)->
    AddPenalty is (Penalty + Num + SoftPenalty);
    AddPenalty is (Penalty + Num)),
    (AddPenalty @< Min ->
    addPenalty(Tasks, NextIndex, AddPenalty, Min, TotalPenalty);
    TotalPenalty is inf).

calc([], LowBounds, LastIsSol, Min, LowBounds, LastIsSol).

calc([H|T], List, ListT, Min, LowBounds, LastIsSol) :-
     addPenalty(H, 0, 0, Min, PenaltySum),
     (PenaltySum @< Min ->
     NewMin is PenaltySum,
     append(List, [PenaltySum], NewList),
     append(ListT, [H], NewListT),
     calc(T, NewList, NewListT, NewMin, LowBounds, LastIsSol);
     calc(T, List, ListT, Min, LowBounds, LastIsSol)).
     
filter([], FilteredC, FilteredC).


filter([H|T], List, FilteredC) :-
    (checkSol(H, 0) ->
    append(List, [H], NewList),
    filter(T, NewList, FilteredC);
    filter(T, List, FilteredC)).

getValidCombo(List, Sol) :-
    findall(X, (permutation(['A','B','C','D','E','F', 'G', 'H'],X),
           nth0(0, X, A),
           \+ forbidden('0',A),
           nth0(1, X, B),
           \+ forbidden('1',B),
           nth0(2, X, C),
           \+ forbidden('2',C),
           nth0(3, X, D),
           \+ forbidden('3',D),
           nth0(4, X, E),
           \+ forbidden('4',E),
           nth0(5, X, F),
           \+ forbidden('5',F),
           nth0(6, X, G),
           \+ forbidden('6',G),
           nth0(7, X, H),
           \+ forbidden('7',H)),
           Combinations),

    length(Combinations, X),
    write(X),
    filter(Combinations, [], FilteredC),
    !,
    calc(FilteredC, [], [], inf, LowBounds, LastIsSol),
    !,
    last(LowBounds, MinLB),
    last(LastIsSol, SolTasks),
    append(List, SolTasks, NewList),
    append(NewList, [MinLB], Sol).


