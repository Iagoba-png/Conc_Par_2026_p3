-module(ring).
-export([start/1, send/3, stop/1]).

%% Inicia un anillo de N procesos (numerados del 0 al N-1).
%% Devuelve el PID del primer proceso.
start(N) when N > 0 ->
    Pids = [spawn(fun() -> ring_process(Num) end) || Num <- lists:seq(0, N-1)],
    %% Configurar el siguiente de cada proceso (el último apunta al primero).
    lists:foreach(fun({Num, Pid}) ->
        Next = lists:nth(((Num+1) rem N) + 1, Pids),
        Pid ! {set_next, Next}
    end, lists:zip(lists:seq(0, N-1), Pids)),
    hd(Pids).

ring_process(Num) ->
    receive
        {set_next, Next} -> ring_loop(Num, Next)
    end.

ring_loop(Num, Next) ->
    receive
        {send, Msg, Remaining} ->
            io:format("~p receiving message ~p with ~p left~n", [Num, Msg, Remaining]),
            if Remaining > 0 ->
                Next ! {send, Msg, Remaining-1};
               true -> ok
            end,
            ring_loop(Num, Next);
        stop ->
            Next ! stop,
            exit(normal)
    end.

%% Envía un mensaje que será procesado por N nodos (dando vueltas si es necesario).
send(Pid, N, Msg) when N > 0 ->
    Pid ! {send, Msg, N-1},
    ok.

%% Detiene todos los procesos del anillo.
stop(Pid) ->
    Pid ! stop,
    ok.