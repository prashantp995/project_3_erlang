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
-export([master/0]).

master() ->
  register(master, self()),
  customer:getCustomerData(),
  bank:getBankData(),
  customer:iterateOver(customermap).