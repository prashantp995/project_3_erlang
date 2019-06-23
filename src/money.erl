%%%-------------------------------------------------------------------
%%% @author prash
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Jun 2019 2:04 PM
%%%-------------------------------------------------------------------
-module(money).
-author("prash").

%% API
-export([start/0, acceptMessages/0]).

start() ->
  register(masterprocess, self()),
  bank:getBankData(),
  Pid = spawn(money, acceptMessages, []),
  register(master, Pid),
  customer:getCustomerData().


printTable(Table) ->
  printTable(Table, ets:first(Table)).
printTable(_Table, '$end_of_table') -> done;
printTable(Table, Key) ->
  if
    Table == customermap ->
      lookupCustomerTableAndPrint(Table, Key);
    true ->
      lookupBankTableAndPrint(Table, Key)
  end,

  printTable(Table, ets:next(Table, Key)).

lookupBankTableAndPrint(Table, Key) ->
  [RemainingBalance] = ets:lookup(Table, Key),
  io:fwrite("~p has ~w dollar(s) remaining.~n", [Key, element(2, RemainingBalance)]).

lookupCustomerTableAndPrint(Table, Key) ->
  [PendingBalance] = ets:lookup(Table, Key),
  [Objective] = ets:lookup(customerinit, Key),
  PendingBalanceValue = element(2, PendingBalance),
  ObjectiveBalanceValue = element(2, Objective),
  TotalBorrowed = ObjectiveBalanceValue - PendingBalanceValue,
  if PendingBalanceValue == 0 ->
    io:fwrite("~p has reached objective of ~w dollar(s) Woo Hoo!.~n", [Key, ObjectiveBalanceValue]);
    true ->
      io:fwrite("~p was only able to borrow ~w dollar(s) Boo Hoo!.~n", [Key, TotalBorrowed])
  end.

acceptMessages() ->
  receive
    {loanRequest, Bank, CustomerName, Amount} ->
      io:format("~p requests a loan of ~p dollar(s) from ~p~n", [CustomerName, Amount, Bank]),
      acceptMessages();
    {requestApproved, Bank, CustomerName, ApprovedAmount} ->
      io:format("~p approves a loan of ~p dollar(s) of ~p~n", [Bank, ApprovedAmount, CustomerName]),
      acceptMessages();
    {deniedRequest, Name, NameofCustomer, AmountRequested} ->
      io:format("~p denied a loan of ~p dollar(s) of ~p~n", [Name, AmountRequested, NameofCustomer]),
      acceptMessages()
  after (800) ->
    io:format("** final Result ***~n"),
    printTable(bankmap),
    printTable(customermap)
  end.
