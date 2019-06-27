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
  Pid = spawn(money, acceptMessages, []),
  register(master, Pid),
  timer:sleep(50),
  io:fwrite("** Banks and financial resources ** ~n"),
  bank:getBankData(),
  io:fwrite("** Customers and loan objectives ** ~n"),
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
  io:fwrite("~w has ~w dollar(s) remaining.~n", [Key, element(2, RemainingBalance)]).

lookupCustomerTableAndPrint(Table, Key) ->
  [PendingBalance] = ets:lookup(Table, Key),
  [Objective] = ets:lookup(customerinit, Key),
  PendingBalanceValue = element(2, PendingBalance),
  ObjectiveBalanceValue = element(2, Objective),
  TotalBorrowed = ObjectiveBalanceValue - PendingBalanceValue,
  if PendingBalanceValue == 0 ->
    io:fwrite("~w has reached objective of ~w dollar(s) Woo Hoo!.~n", [Key, ObjectiveBalanceValue]);
    true ->
      io:fwrite("~w was only able to borrow ~w dollar(s) Boo Hoo!.~n", [Key, TotalBorrowed])
  end.

acceptMessages() ->
  receive
    {pritCustomerObjective, CustomerName, LoanRequested} ->
      io:fwrite("~w : ~w ~n", [CustomerName, LoanRequested]),
      acceptMessages();
    {pritInitialBankDetails, BankName, Totalfunds} ->
      io:fwrite("~w : ~w ~n", [BankName, Totalfunds]),
      acceptMessages();
    {loanRequest, Bank, CustomerName, Amount} ->
      io:format("~w requests a loan of ~w dollar(s) from ~w~n", [CustomerName, Amount, Bank]),
      acceptMessages();
    {requestApproved, Bank, CustomerName, ApprovedAmount} ->
      io:format("~w approves a loan of ~w dollar(s) of ~w~n", [Bank, ApprovedAmount, CustomerName]),
      acceptMessages();
    {deniedRequest, Name, NameofCustomer, AmountRequested} ->
      io:format("~w denied a loan of ~w dollar(s) of ~w~n", [Name, AmountRequested, NameofCustomer]),
      acceptMessages()
  after (1000) ->
    io:format("** final Result ***~n"),
    printTable(bankmap),
    printTable(customermap)
  end.
