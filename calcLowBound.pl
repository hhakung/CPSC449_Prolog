% Author:
% Date: 4/12/2018


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

getValidCombo(LowBounds, LastIsSol) :-
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
    !.



