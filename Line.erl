-module(line).
-export([start/1, send/2, bounce/3, stop/1]).

%% Inicia una línea de N procesos (numerados del 0 al N-1).
%% Devuelve el PID del primer proceso.
start(N) when N > 0 ->
    %% Crear procesos en orden inverso para poder pasar el siguiente al crearlos.
    %% La lista resultante queda en orden directo: [P0, P1, ..., P{N-1}].
    Pids = lists:foldl(fun(Num, Acc) ->
        Next = case Acc of
            [] -> none;
            [H | _] -> H
        end,
        Pid = spawn(fun() -> process_loop(Num, Next) end),
        [Pid | Acc]
    end, [], lists:seq(N-1, 0, -1)),
    %% Enviar a cada proceso el PID de su anterior.
    set_prev(Pids, none),
    hd(Pids).

set_prev([], _) -> ok;
set_prev([Pid | Rest], Prev) ->
    Pid ! {set_prev, Prev},
    set_prev(Rest, Pid).

process_loop(Num, Next) ->
    receive
        {set_prev, Prev} -> loop(Num, Next, Prev)
    end.

loop(Num, Next, Prev) ->
    receive
        {send, Msg} ->
            io:format("~p received message ~p~n", [Num, Msg]),
            if Next =/= none -> Next ! {send, Msg}; true -> ok end,
            loop(Num, Next, Prev);
        {bounce, Msg, Times, Dir} ->
            io:format("~p received message ~p~n", [Num, Msg]),
            NewTimes = Times - 1,
            if NewTimes == 0 ->
                ok;
            true ->
                NewDir = case {Dir, Next, Prev} of
                    {forward, none, _} -> backward;
                    {backward, _, none} -> forward;
                    _ -> Dir
                end,
                case NewDir of
                    forward -> if Next =/= none -> Next ! {bounce, Msg, NewTimes, forward}; true -> ok end;
                    backward -> if Prev =/= none -> Prev ! {bounce, Msg, NewTimes, backward}; true -> ok end
                end
            end,
            loop(Num, Next, Prev);
        stop ->
            if Next =/= none -> Next ! stop; true -> ok end,
            exit(normal)
    end.

%% Envía un mensaje que se propaga hasta el final de la línea.
send(Pid, Msg) ->
    Pid ! {send, Msg},
    ok.

%% Envía un mensaje que rebota entre los extremos Times veces.
bounce(Pid, Msg, Times) when Times > 0 ->
    Pid ! {bounce, Msg, Times, forward},
    ok.

%% Detiene todos los procesos de la línea.
stop(Pid) ->
    Pid ! stop,
    ok.