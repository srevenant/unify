{application,rivet_test_lib,
             [{compile_env,[{elixir,[dbg_callback],
                                    {ok,{'Elixir.Macro',dbg,[]}}}]},
              {applications,[kernel,stdlib,elixir,rivet]},
              {description,""},
              {modules,['Elixir.RivetTestLib',
                        'Elixir.RivetTestLib.Yoink']},
              {registered,[]},
              {vsn,"1.0.6"},
              {env,[{rivet, [{app, rivet_test_lib}]}]}]}.

