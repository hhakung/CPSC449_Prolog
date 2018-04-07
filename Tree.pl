% Machine penalties for testing
getMachinePenalties([[1,2,3,4,5,6,7,8],[2,3,4,5,6,7,8,9],[3,4,5,6,7,8,9,10],
                   [4,5,6,7,8,9,10,11],[5,6,7,8,9,10,11,12],[6,7,8,9,10,11,12,13],
                   [7,8,9,10,11,12,13,14],[8,9,10,11,12,13,14,15]]).

% Convert the task to integer
% A = 0, B = 1, C = 2, D = 3, E = 4, F = 5, G = 6, H = 7 otherwise -1
taskToInt(Task, IntVal) :-
                ( char_code(Task, CharCode), (CharCode < 65; CharCode > 72) -> IntVal is -1
                ; char_code(Task, CharCode), IntVal is CharCode - 65).

% Convert the integer to task
% 0 = A, 1 = B, 2 = C, 3 = D, 4 = E, 5 = F, 6 = G, 7 = H otherwise Z
intToTask(IntVal, Task) :-
                  ( CharCode is IntVal + 65, (CharCode < 65; CharCode > 72) -> Task = 'Z'
                  ; CharCode is IntVal + 65, char_code(Task, CharCode)).

% Get element with index (x, y) from machine penalties array
getElement(X, Y, Element) :- getMachinePenalties(Array),nth0(X, Array, Row),
                                    nth0(Y, Row, Element).

% Get the index of element (first element if there are more than one) with lowest value
% Not catching exception yet (empty list)
minLowerBound(Array, Index) :- min_list(Array, X), getIndex(X, Array, Index).

% Get the index of given element in Array
% Not catching exception yet (empty list)
getIndex(X, Array, Index) :- nth0(Index, Array, X).


% Write to the outputFile
% Works as main (?)
assignTasks(InputFile, OutputFile) :-
                       open(OutputFile, write, File),
                       write(File, 'abcdefg'),
                       close(File).