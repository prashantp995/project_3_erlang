%%%-------------------------------------------------------------------
%%% @author prash
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Jun 2019 2:05 PM
%%%-------------------------------------------------------------------
-module(customer).
-author("prash").

%% API
-export([getCustomerData/0, createCustomerProcess/2, customerProcess/4,
  startLoanProcess/1, startLoan/3, createAndRegister/2, sendObjectivesToMaster/1]).

getCustomerData() ->
  ets:new(customermap, [ordered_set, named_table, set, public]),
  ets:new(customerinit, [ordered_set, named_table, set, public]),
  {ok, Customers} = file:consult("customers.txt"),
  {ok, EligibleBanks} = file:consult("banks.txt"),
  CustomerData = fun(SingleTupleCustomer) ->
    sendObjectivesToMaster(SingleTupleCustomer) end,
  lists:foreach(CustomerData, Customers),
  CustomersObj = fun(SingleTupleCustomer) ->
    createCustomerProcess(SingleTupleCustomer, EligibleBanks) end,
  lists:foreach(CustomersObj, Customers).

startLoanProcess(CustomerName) ->
  [Rec] = ets:lookup(customermap, CustomerName),
  LoanAmountRequest = element(2, Rec),
  {ok, Banks} = file:consult("banks.txt"),
  startLoan(CustomerName, LoanAmountRequest, Banks).

startLoan(CustomerName, RequestedAmount, PossibleBankList) ->
  if
    RequestedAmount /= 0 ->
      if
        RequestedAmount < 50 ->
          RandomAmountToRequest = getRandomNumber(RequestedAmount);
        true -> RandomAmountToRequest = getRandomNumber(50)
      end,
      RandomPause = rand:uniform(100),
      if
        RandomPause < 10 ->
          FinalPause = RandomPause + 10;
        true ->
          FinalPause = RandomPause
      end,
      timer:sleep(FinalPause),
      {RandomIndex, SelectedBank} = selectRandomBank(PossibleBankList),
      RandomBankTuple = lists:nth(RandomIndex, PossibleBankList),
      {MasterProcessID, BankProcessId} = getMasterAndBankProcessID(SelectedBank),
      MasterProcessID ! {loanRequest, SelectedBank, CustomerName, RandomAmountToRequest},
      BankProcessId ! {requestloan, CustomerName, RandomAmountToRequest, SelectedBank, RandomBankTuple, RandomIndex, PossibleBankList};
    true -> false
  end.

selectRandomBank(PossibleBankList) ->
  Index = rand:uniform(length(PossibleBankList)),
  {SelectedBank, _} = lists:nth(Index, PossibleBankList),
  {Index, SelectedBank}.

getMasterAndBankProcessID(SelectedBank) ->
  MasterProcessID = whereis(master),
  BankProcessId = whereis(SelectedBank),
  {MasterProcessID, BankProcessId}.

getRandomNumber(RequestedAmount) ->
  rand:uniform(RequestedAmount).

createCustomerProcess(SingleTupleCustomer, EligibleBanks) ->
  createAndRegister(SingleTupleCustomer, EligibleBanks),
  {CustomerName, LoanRequested} = getElements(SingleTupleCustomer),
  ets:insert(customermap, {CustomerName, LoanRequested}),
  ets:insert(customerinit, {CustomerName, LoanRequested}),
  startLoanProcess(CustomerName).

getElements(SingleTupleCustomer) ->
  CustomerName = element(1, SingleTupleCustomer),
  LoanRequested = element(2, SingleTupleCustomer),
  {CustomerName, LoanRequested}.

createAndRegister(SingleTupleCustomer, EligibleBanks) ->
  CustomerName = element(1, SingleTupleCustomer),
  AmountRequested = element(2, SingleTupleCustomer),
  _Pid = spawnAndRegister(CustomerName, AmountRequested, EligibleBanks).

spawnAndRegister(CustomerName, AmountRequested, EligibleBanks) ->
  Pid = spawn(customer, customerProcess, [CustomerName, AmountRequested, EligibleBanks, 0]),
  register(CustomerName, Pid),
  Pid.

customerProcess(CustomerName, AmountRequested, EligibleBanks, ApprovedAmount) ->

  receive
    {CustomerName, AmountRequested, EligibleBanks, ApprovedAmount} ->
      customerProcess(CustomerName, AmountRequested, EligibleBanks, ApprovedAmount);
    {requestApproved, LoanAmount, PossibleBankList} ->
      startLoan(CustomerName, AmountRequested - LoanAmount, PossibleBankList),
      customerProcess(CustomerName, AmountRequested - LoanAmount, PossibleBankList, ApprovedAmount + LoanAmount);
    {deniedRequest, _LoanAmount, _RandomBankTuple, _BankPositionInMap, PossibleBankList} ->
      ListSize = length(PossibleBankList),
      if
        ListSize > 0 ->
          startLoan(CustomerName, AmountRequested, PossibleBankList),
          customerProcess(CustomerName, AmountRequested, PossibleBankList, ApprovedAmount);
        true ->
          io:fwrite("~n")
      end

  end.


sendObjectivesToMaster(SingleTupleCustomer) ->
  {CustomerName, LoanRequested} = getElements(SingleTupleCustomer),
  MasterPID = whereis(master),
  MasterPID ! {pritCustomerObjective, CustomerName, LoanRequested}.
