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
-export([getCustomerData/0, createCustomerProcess/1, customerProcess/1]).

getCustomerData() ->
  io:fwrite("get customer data is called ~n"),
  {ok, Customers} = file:consult("src/customers.txt"),
  CustomersObj = fun(SingleTupleCustomer) -> createCustomerProcess(SingleTupleCustomer) end,
  lists:foreach(CustomersObj, Customers).

createCustomerProcess(SingleTupleCustomer) ->
  Pid = spawn(customer, customerProcess, [SingleTupleCustomer]),
  CustomerName = element(1, SingleTupleCustomer),
  LoanRequested = element(2, SingleTupleCustomer),
  io:fwrite("~w: ~w~n", [CustomerName, LoanRequested]),
  register(element(1, SingleTupleCustomer), Pid),
  timer:sleep(100).

customerProcess(Customer) ->
  receive
    {Name, LoanRequested} ->
      io:fwrite("customer received request")
  end.
