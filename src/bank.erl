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
-export([getBankData/0, bankProcess/2, sendInitDetailsToMaster/1]).


getBankData() ->
  io:fwrite("-----------------------------------Reading Banks' Data------------------------------- ~n"),
  {ok, BankData} = file:consult("banks.txt"),
  ets:new(bankmap, [ordered_set, named_table, set, public]),
  BankDetails = fun(SingleTupleBank) ->
    sendInitDetailsToMaster(SingleTupleBank) end,
  lists:foreach(BankDetails, BankData),
  BankObj = fun(SingleTupleBank) -> createBankProcess(SingleTupleBank) end,
  lists:foreach(BankObj, BankData).

createBankProcess(SingleTupleBank) ->
  {BankName, Totalfunds} = getElements(SingleTupleBank),
  createAndregister(BankName, Totalfunds),
  etsinsertToBank(BankName, Totalfunds).

getElements(SingleTupleBank) ->
  BankName = element(1, SingleTupleBank),
  Totalfunds = element(2, SingleTupleBank),
  {BankName, Totalfunds}.

createAndregister(BankName, TotalFund) ->
  Pid = spawn(bank, bankProcess, [BankName, TotalFund]),
  register(BankName, Pid).

etsinsertToBank(BankName, Totalfunds) ->
  ets:insert(bankmap, {BankName, Totalfunds}).

etsinsertToCustomer(CustomerName, UpdatedFund) ->
  ets:insert(customermap, {CustomerName, UpdatedFund}).


bankProcess(Name, TotalFund) ->
  receive
    {requestloan, NameofCustomer, AmountRequested, _RequestedBank, RandomBankTuple, IndexOfSelctedBank, PossibleBankList} ->
      if
        (AmountRequested > 0) and (TotalFund >= AmountRequested) and (TotalFund > 0) ->
          [Record] = ets:lookup(bankmap, Name),
          Fund = element(2, Record),
          UpdatedFund = Fund - AmountRequested,
          etsinsertToBank(Name, UpdatedFund),

          [CustomerRecord] = ets:lookup(customermap, NameofCustomer),
          TotalRequestForCustomer = element(2, CustomerRecord),
          UpdatedRequest = TotalRequestForCustomer - AmountRequested,
          etsinsertToCustomer(NameofCustomer, UpdatedRequest),

          {MasterID, MasterID, Name, NameofCustomer, AmountRequested} = sendUpdateTomaster(Name, NameofCustomer, AmountRequested),
          CustomerID = whereis(NameofCustomer),
          CustomerID ! {requestApproved, AmountRequested, PossibleBankList},
          bankProcess(Name, TotalFund - AmountRequested);
        true ->
          Tuple = lists:nth(IndexOfSelctedBank, PossibleBankList),
          NewBanks = lists:delete(Tuple, PossibleBankList),
          MasterID = whereis(master),
          MasterID ! {deniedRequest, Name, NameofCustomer, AmountRequested},
          CustomerID = whereis(NameofCustomer),
          CustomerID ! {deniedRequest, AmountRequested, RandomBankTuple, IndexOfSelctedBank, NewBanks},
          bankProcess(Name, TotalFund)
      end
  end.

sendUpdateTomaster(Name, NameofCustomer, AmountRequested) ->
  MasterID = whereis(master),
  MasterID ! {requestApproved, Name, NameofCustomer, AmountRequested},
  {MasterID, MasterID, Name, NameofCustomer, AmountRequested}.


sendInitDetailsToMaster(SingleTupleBank) ->
  {BankName, Totalfunds} = getElements(SingleTupleBank),
  MasterPID = whereis(master),
  MasterPID ! {pritInitialBankDetails, BankName, Totalfunds}.