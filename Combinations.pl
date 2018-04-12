% Author:
% Date: 4/12/2018

%forbidden('1', 'A').
%forced('1', 'B').

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
    %forced(Mach, Task) ->
    %append(Combination, [Task], NewCombo)
    %delete(['A','B','C'], Task, NewRemainT),
    %getCombination(Mach, NewRemainT, NewCombo, ComboArray);
    %forbidden(Mach, H) -> iterate(T, Mach, Combination, ComboArray);
    append(Combination, [H], NewCombo),
    getCombination(Mach, ['A','B','C'], NewCombo, ComboArray),
    iterate(T, Mach, Combination, ComboArray).


getCombination('2',  RemainTask, Combination, ComboArray) :-
    add_list(Combination, ComboArray, List).
    write(Combination).

getCombination(Mach , RemainTask, Combination, ComboArray) :-
    atom_number(Mach, M ),
    N is M+1,
    atom_number(X, N),
    iterate(RemainTask, X, Combination, ComboArray).
    
add_list([], L, L).
add_list([H|T],L,L1) :- add(H, L2, L1), add_list(T, L, L2).
