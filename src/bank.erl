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
  ets:new(bankmap, [ordered_set, named_table, set, public]),
  BankObj = fun(SingleTupleBank) -> createBankProcess(SingleTupleBank) end,
  lists:foreach(BankObj, Banks).

createBankProcess(SingleTupleBank) ->

  createAndregister(SingleTupleBank),
  {BankName, Totalfunds} = getElements(SingleTupleBank),
  etsinsert(BankName, Totalfunds),
  io:fwrite("~w: ~w~n", [BankName, Totalfunds]),
  timer:sleep(100),
  Rec = list_etslookup(BankName),
  Totalfunds_1 = element(2, Rec).

list_etslookup(BankName) ->
  [Rec] = ets:lookup(bankmap, BankName),
  Rec.

getElements(SingleTupleBank) ->
  BankName = element(1, SingleTupleBank),
  Totalfunds = element(2, SingleTupleBank),
  {BankName, Totalfunds}.

createAndregister(SingleTupleBank) ->
  timer:sleep(100),
  Pid = spawn(bank, bankProcess, [SingleTupleBank]),
  register(element(1, SingleTupleBank), Pid),
  io:fwrite("~w", [Pid]).

etsinsert(BankName, Totalfunds) ->
  ets:insert(bankmap, {BankName, Totalfunds}).

bankProcess(Bank) ->
  receive
    {CustomerName, LoanAmount, BankName} ->
      io:fwrite("~w Requested ~w From ~w~n", [CustomerName, LoanAmount, BankName]),
      bankProcess(Bank)
  end.
