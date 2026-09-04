%%%-------------------------------------------------------------------
%%% @doc velora_tiles_filter boot (application + supervisor).
%%%
%%% A thin Emergence adapter: it registers an imagery/satellite agent on the
%%% em_filter mesh and, for each query, forwards it to a running velora node
%%% (the "eyes of Emergence") with intent "tiles". velora does the heavy
%%% geocoding/STAC/warp work and returns tile cards; this filter only relays
%%% them into the mesh (rewriting velora's host-relative URLs to absolute).
%%%
%%% Follows the current em_filter agent model (em_filter:start_agent/3): the
%%% framework owns the em_disco WebSocket connection, JWT auth and em_pop node;
%%% the handler module supplies handle/2 + base_capabilities/0.
%%%
%%% Handler config keys (application env, read in velora_tiles_filter_handler):
%%%   velora_url — velora /agent/query endpoint (default 127.0.0.1:8081)
%%%   tiles_base — public base used to absolutize velora card URLs
%%% @end
%%%-------------------------------------------------------------------
-module(velora_tiles_filter_app).
-behaviour(application).
-behaviour(supervisor).

-export([start/2, stop/1, init/1]).

start(_Type, _Args) ->
    {ok, Pid} = supervisor:start_link({local, velora_tiles_filter_boot_sup},
                                      ?MODULE, []),
    _ = application:ensure_all_started(em_filter),
    _ = em_filter:start_agent(velora_tiles_filter, velora_tiles_filter_handler,
          #{pop_port     => 9210,
            query_port   => 9211,
            capabilities => velora_tiles_filter_handler:base_capabilities(),
            pop_peers    => [{"localhost", 9101}],
            pop_role     => leaf}),
    {ok, Pid}.

stop(_State) -> ok.

init([]) ->
    {ok, {#{strategy => one_for_one, intensity => 1, period => 5}, []}}.
