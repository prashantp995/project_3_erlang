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
-export([master/0, acceptMessages/0]).

master() ->
  register(masterprocess, self()),
  Pid = spawn(money, acceptMessages, []),
  register(master, Pid),
  bank:getBankData(),
  customer:getCustomerData(),
  %customer:iterateOver(customermap),
  timer:sleep(100),

  timer:sleep(100).



acceptMessages() ->
  receive
    {loanRequest, Bank, CustomerName, Amount} ->
      io:format("~p requests a loan of ~p dollar(s) from ~p~n", [CustomerName, Amount, Bank]),
      acceptMessages();
    {requestApproved, Bank, CustomerName, ApprovedAmount} ->
      io:format("~p approves a loan of ~p dollar(s) of ~p~n", [Bank, ApprovedAmount, CustomerName]),
      acceptMessages()

  end.
