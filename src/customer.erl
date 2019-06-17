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
-export([getCustomerData/0, createCustomerProcess/1, customerProcess/1, iterateOver/1, iterateOver/2, removeZerocase/1]).

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

iterateOver(Table) ->
  iterateOver(Table, ets:first(Table)).

iterateOver(Table, '$end_of_table') ->
  Key = ets:first(Table),
  [Rec] = ets:lookup(customermap, Key),
  RemainingLoanAmount = element(2, Rec),
  if RemainingLoanAmount =< 0
    -> io:fwrite("eot ~w Remaining ~w", [Key, RemainingLoanAmount]),
    iterateOver(Table, ets:next(Table, Key));
    true -> iterateOver(Table, ets:first(Table))
  end;


iterateOver(Table, Key) ->
  [Rec] = ets:lookup(Table, Key),
  RecBank_1 = ets:first(bankmap),
  [RecBank] = ets:lookup(bankmap, RecBank_1),
  BankName = element(1, RecBank),
  CustomerName = element(1, Rec),
  LoanAmount = element(2, Rec),
  timer:sleep(100),
  if
    LoanAmount > 50 ->
      LoanAmount_1 = rand:uniform(50),
      timer:sleep(100),
      BankPid = whereis(BankName),
      BankPid ! {CustomerName, LoanAmount_1, BankName},
      iterateOver(Table, ets:next(Table, Key));
    true ->
      if LoanAmount =< 0
        -> io:fwrite("it is less than zero~n"),
        iterateOver(Table, ets:next(Table, Key));
        true ->
          LoanAmount_2 = rand:uniform(LoanAmount),
          timer:sleep(100),
          BankPid_1 = whereis(BankName),
          BankPid_1 ! {CustomerName, LoanAmount, BankName},
          iterateOver(Table, ets:next(Table, Key)),
          timer:sleep(100)
      end,
      io:fwrite("~n")

  end.




removeZerocase(SingleTupleCustomer) ->
  io:fwrite("removeZerocasecalled").