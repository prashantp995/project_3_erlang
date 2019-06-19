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
  startLoanProcess/1, startLoan/3, createAndRegister/2]).

getCustomerData() ->
  io:fwrite("get customer data is called ~n"),
  ets:new(customermap, [ordered_set, named_table, set, public]),
  {ok, Customers} = file:consult("src/customers.txt"),
  {ok, EligibleBanks} = file:consult("src/banks.txt"),
  CustomersObj = fun(SingleTupleCustomer) ->
    createCustomerProcess(SingleTupleCustomer, EligibleBanks) end,
  lists:foreach(CustomersObj, Customers).

startLoanProcess(CustomerName) ->
  [Rec] = ets:lookup(customermap, CustomerName),
  LoanAmountRequest = element(2, Rec),
  {ok, Banks} = file:consult("src/banks.txt"),
  startLoan(CustomerName, LoanAmountRequest, Banks).

startLoan(CustomerName, RequestedAmount, PossibleBankList) ->
  if
    RequestedAmount /= 0 ->
      timer:sleep(100),
      if
        RequestedAmount < 50 ->
          RandomAmountToRequest = getRandomNumber(RequestedAmount);
        true -> RandomAmountToRequest = getRandomNumber(50)
      end,
      RandomIndex = rand:uniform(length(PossibleBankList)),
      RandomBank = lists:nth(RandomIndex, PossibleBankList),
      {SelectedBank, _} = lists:nth(RandomIndex, PossibleBankList),
      MasterProcessID = whereis(master),
      BankProcessId = whereis(SelectedBank),
      MasterProcessID ! {loanRequest, SelectedBank, CustomerName, RandomAmountToRequest},
      BankProcessId ! {requestloan, CustomerName, RandomAmountToRequest, RandomBank};
    true -> false
  end.

getRandomNumber(RequestedAmount) ->
  rand:uniform(RequestedAmount).

createCustomerProcess(SingleTupleCustomer, EligibleBanks) ->
  createAndRegister(SingleTupleCustomer, EligibleBanks),
  {CustomerName, LoanRequested} = getElements(SingleTupleCustomer),
  ets:insert(customermap, {CustomerName, LoanRequested}),
  io:fwrite("~w: ~w~n", [CustomerName, LoanRequested]),
  timer:sleep(100),
  startLoanProcess(CustomerName).

getElements(SingleTupleCustomer) ->
  CustomerName = element(1, SingleTupleCustomer),
  LoanRequested = element(2, SingleTupleCustomer),
  {CustomerName, LoanRequested}.

createAndRegister(SingleTupleCustomer, EligibleBanks) ->
  CustomerName = element(1, SingleTupleCustomer),
  AmountRequested = element(2, SingleTupleCustomer),
  Pid = spawn(customer, customerProcess, [CustomerName, AmountRequested, EligibleBanks, 0]),
  register(CustomerName, Pid),
  io:fwrite("~w", [Pid]).

customerProcess(CustomerName, AmountRequested, EligibleBanks, ApprovedAmount) ->

  receive
    {CustomerName, AmountRequested, EligibleBanks, ApprovedAmount} ->
      io:fwrite("customer loan processed for request-->~w", [CustomerName]),
      customerProcess(CustomerName, AmountRequested, EligibleBanks, ApprovedAmount);
    {grantReq, LoanAmount} ->
      io:fwrite("LoanApproved for amount ~w ~n", [LoanAmount]),
      startLoan(CustomerName, AmountRequested - LoanAmount, EligibleBanks),
      customerProcess(CustomerName, AmountRequested - LoanAmount, EligibleBanks, ApprovedAmount + LoanAmount)
  end.
