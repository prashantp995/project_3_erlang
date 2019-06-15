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
-export([getCustomerData/0, createCustomerProcess/1, customerProcess/1, matching/1, matching/2]).

getCustomerData() ->
  io:fwrite("get customer data is called ~n"),
  ets:new(customermap, [ordered_set, named_table, set, public]),
  {ok, Customers} = file:consult("src/customers.txt"),
  CustomersObj = fun(SingleTupleCustomer) -> createCustomerProcess(SingleTupleCustomer) end,
  lists:foreach(CustomersObj, Customers).

createCustomerProcess(SingleTupleCustomer) ->
  createAndRegister(SingleTupleCustomer),
  {CustomerName, LoanRequested} = getElements(SingleTupleCustomer),
  ets:insert(customermap, {CustomerName, LoanRequested}),
  io:fwrite("~w: ~w~n", [CustomerName, LoanRequested]),
  timer:sleep(100).

getElements(SingleTupleCustomer) ->
  CustomerName = element(1, SingleTupleCustomer),
  LoanRequested = element(2, SingleTupleCustomer),
  {CustomerName, LoanRequested}.

createAndRegister(SingleTupleCustomer) ->
  Pid = spawn(customer, customerProcess, [SingleTupleCustomer]),
  register(element(1, SingleTupleCustomer), Pid).

customerProcess(Customer) ->
  receive
    {Name, LoanRequested} ->
      io:fwrite("customer received request")
  end.

matching(Table) ->
  matching(Table, ets:first(Table)).

matching(_Table, '$end_of_table') -> done;

matching(Table, Key) ->
  [Rec] = ets:lookup(Table, Key),
  RecBank_1 = ets:first(bankmap),
  [RecBank] = ets:lookup(bankmap, RecBank_1),
  BankName = element(1, RecBank),
  io:format("~p: ~p~n", [Key, Rec]),
  CustomerName = element(1, Rec),
  LoanAmount = element(2, Rec),
  timer:sleep(100),
  BankPid = whereis(BankName),
  BankPid ! {CustomerName, LoanAmount, BankName},
  matching(Table, ets:next(Table, Key)).

