-module(queue).
-export([empty/0, insert/2, remove/1]).

%% Devuelve una cola vacía representada como [Front, Back]
empty() -> [[], []].

%% Inserta un elemento al final de la cola (coste O(1))
insert([F, B], Elem) -> [F, [Elem | B]].

%% Elimina el elemento del frente de la cola.
%% Devuelve {ok, Elem, NuevaCola} o el átomo 'empty' si la cola está vacía.
remove([[], []]) -> empty;
remove([[], B]) ->
    [NewFrontElem | RestFront] = lists:reverse(B),
    {ok, NewFrontElem, [RestFront, []]};
remove([[H | T], B]) ->
    {ok, H, [T, B]}.