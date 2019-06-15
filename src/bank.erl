%%%-------------------------------------------------------------------
%%% @author prash
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Jun 2019 2:05 PM
%%%-------------------------------------------------------------------
-module(bank).
-author("prash").

%% API
-export([getBankData/0, bankProcess/1]).


getBankData() ->
  io:fwrite("-----------------------------------Reading Banks' Data------------------------------- ~n"),
  {ok, Banks} = file:consult("src/banks.txt"),
  BankObj = fun(SingleTupleBank) -> createBankProcess(SingleTupleBank) end,
  lists:foreach(BankObj, Banks).

createBankProcess(SingleTupleBank) ->

  Pid = spawn(bank, bankProcess, [SingleTupleBank]),
  register(element(1, SingleTupleBank), Pid),
  BankName = element(1, SingleTupleBank),
  Totalfunds = element(2, SingleTupleBank),
  io:fwrite("~w: ~w~n", [BankName, Totalfunds]),
  timer:sleep(100).

bankProcess(Bank) ->
  receive
    {BankName, Fund} ->
      io:fwrite("~w", [Bank])
  end.
