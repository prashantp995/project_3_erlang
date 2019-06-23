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
-export([getBankData/0, bankProcess/2, printObjectives/1]).


getBankData() ->
  io:fwrite("-----------------------------------Reading Banks' Data------------------------------- ~n"),
  {ok, BankData} = file:consult("src/banks.txt"),
  ets:new(bankmap, [ordered_set, named_table, set, public]),
  io:fwrite("** Banks and financial resources ** ~n"),
  BankDetails = fun(SingleTupleBank) ->
    printObjectives(SingleTupleBank) end,
  lists:foreach(BankDetails, BankData),
  BankObj = fun(SingleTupleBank) -> createBankProcess(SingleTupleBank) end,
  lists:foreach(BankObj, BankData).

createBankProcess(SingleTupleBank) ->
  {BankName, Totalfunds} = getElements(SingleTupleBank),
  createAndregister(BankName, Totalfunds),
  etsinsert(BankName, Totalfunds),
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

createAndregister(BankName, TotalFund) ->
  timer:sleep(100),
  Pid = spawn(bank, bankProcess, [BankName, TotalFund]),
  register(BankName, Pid).

etsinsert(BankName, Totalfunds) ->
  ets:insert(bankmap, {BankName, Totalfunds}).

etsinsertToCustomer(CustomerName, UpdatedFund) ->
  ets:insert(customermap, {CustomerName, UpdatedFund}).


bankProcess(Name, TotalFund) ->
  receive
    {requestloan, NameofCustomer, AmountRequested, RequestedBank, RandomBankTuple, RandomIndex, PossibleBankList} ->
      if
        (AmountRequested > 0) and (TotalFund >= AmountRequested) and (TotalFund > 0) ->
          [Record] = ets:lookup(bankmap, Name),
          Fund = element(2, Record),
          UpdatedFund = Fund - AmountRequested,
          etsinsert(Name, UpdatedFund),

          [CustomerRecord] = ets:lookup(customermap, NameofCustomer),
          TotalRequestForCustomer = element(2, CustomerRecord),
          UpdatedRequest = TotalRequestForCustomer - AmountRequested,
          etsinsertToCustomer(NameofCustomer, UpdatedRequest),

          {MasterID, MasterID, Name, NameofCustomer, AmountRequested} = sendUpdateTomaster(Name, NameofCustomer, AmountRequested),
          CustomerID = whereis(NameofCustomer),
          CustomerID ! {requestApproved, AmountRequested, PossibleBankList},
          bankProcess(Name, TotalFund - AmountRequested);
        true ->
          Tuple = lists:nth(RandomIndex, PossibleBankList),
          NewBanks = lists:delete(Tuple, PossibleBankList),
          MasterID = whereis(master),
          MasterID ! {deniedRequest, Name, NameofCustomer, AmountRequested},
          CustomerID = whereis(NameofCustomer),
          CustomerID ! {deniedRequest, AmountRequested, RandomBankTuple, RandomIndex, NewBanks},
          bankProcess(Name, TotalFund)
      end;

    {CustomerName, LoanAmount, BankName} ->
      io:fwrite("~w Requested ~w From ~w~n", [CustomerName, LoanAmount, BankName]),
      [Record] = ets:lookup(bankmap, BankName),
      Fund = element(2, Record),

      [CustomerRecord] = ets:lookup(customermap, CustomerName),
      TotalRequestForCustomer = element(2, CustomerRecord),
      UpdatedRequest = TotalRequestForCustomer - LoanAmount,
      if
        UpdatedRequest =< 0 ->
          etsinsertToCustomer(CustomerName, 0),
          CustomerProcessID = whereis(CustomerName),
          CustomerProcessID ! {CustomerName, 20};
        true ->
          if
            Fund > LoanAmount ->
              UpdatedFund = Fund - LoanAmount,
              etsinsert(BankName, UpdatedFund),
              etsinsertToCustomer(CustomerName, UpdatedRequest),
              io:fwrite("~w Approved Loan Application of ~w For ~w Amount ~n", [BankName, CustomerName, LoanAmount]);
            true ->
              io:fwrite("~w Rejected Loan Application of ~w For ~w Amount ~n", [BankName, CustomerName, LoanAmount])
          end
      end,
      bankProcess(Name, TotalFund)
  end.

sendUpdateTomaster(Name, NameofCustomer, AmountRequested) ->
  MasterID = whereis(master),
  MasterID ! {requestApproved, Name, NameofCustomer, AmountRequested},
  {MasterID, MasterID, Name, NameofCustomer, AmountRequested}.


printObjectives(SingleTupleBank) ->
  {BankName, Totalfunds} = getElements(SingleTupleBank),
  io:fwrite("~w : ~w ~n", [BankName, Totalfunds]).