forbidden('-1', 'A').
%forbidden('1', 'A').
%forbidden('0', 'B').

forced('-1','A').

hardTooNear('Z','Z').
hardTooNear('A','B').
hardTooNear('A','C').


getPenalty(Solution,Value):-
    Value = Solution.

calcPenalty(Solutions, Penalties) :-
    foreach(member(X,Solutions),
	    (getPenalty(X,Y),writeln(Y))).


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
    value is C1 + C2 + C3 + C4 + C5 + C6 + C7 + C8 + S1 + S2 + S3 + S4 + S5 +S6 + S7 + S8.
    
