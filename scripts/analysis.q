\c 25 180
\p 8848

system "l utils.q";
system "l create_network.q";

.agrar.analyze.tiborcz:{[]
  .tiborcz.raw: select from .agrar.ppl where upper[name] like "*TIBORCZ*";
  .tiborcz.overview: select count i, sum amount by name,zip,address from .tiborcz.raw;
  .tiborcz.yearly_wins: select sum amount by year from .tiborcz.raw;
  .tiborcz.avg_wins: `avg_win xdesc update avg_win:amt%cnt from select amt: sum amount,cnt: count i by address from .tiborcz.raw;
  .agrar.save_csv["tiborcz_wins";.tiborcz.yearly_wins];
  };

.agrar.analyze.felcsut:{[]
  // Felcsut and neighboring towns
  .felcsut.raw: select from .agrar.ppl where zip in (8086;8087;2063;2066;2060;2065;2091);
  .felcsut.big_wins: `amount xdesc select count i, sum amount by name, address from .felcsut.raw;
  .felcsut.compact: .agrar.create_compact[.felcsut.raw;2500000];
  .felcsut.compact: update settlement_addr:{`$ string[x]," ",string[y]}'[settlement;address] from .felcsut.compact;
  .felcsut.network: .agrar.create_network_full[.felcsut.compact];

  .felcsut.avg_wins: `avg_win xdesc update avg_win:amt%cnt from select amt: sum amount,cnt: count i by name,settlement,
  address from .felcsut.raw;

  .felcsut.non_zero: select name1,settlement1,address1,amount1,name2,settlement2,address2,amount2,address_score,
  name_score, score from (update zero_one: {$[x<3;:0;:1]}'[score] from .felcsut.network) where zero_one=1;
  .agrar.save_csv["felcsut_network"; .felcsut.non_zero];
  .agrar.save_csv["felcsut_avg_wins"; .felcsut.avg_wins];
  };

.agrar.analyze.big_wins:{[]
  // Are there individuals and firms that share address?
  .misc.same_addresses: (`zip`settlement`address xkey .agrar.firms) ij `zip`settlement`address xkey .agrar.ppl;

  // Residents of which town won the largest amount of subsidies - order by average wins
  .misc.ppl_wins_avg: `avg_amt xdesc update avg_amt: amount%wins from select sum amount, wins: count i by settlement,
  zip from .agrar.ppl;

  // Firms of which town won the most money - order by average amount
  .misc.firm_wins: `avg_amt xdesc update avg_amt: amount%wins from select sum amount, wins: count i by settlement,zip
  from .agrar.firms;

  // Which individuals won the most in agricultural subsidies
  .misc.ppl_wins_max: () xkey `amount xdesc select sum amount,count i by name,settlement,address from .agrar.ppl;

  // which households contain the most winners (along with the amounts)
  .misc.single_household: select from (`cnt xdesc select nm: enlist name, cnt: count i,sum amount by
  settlement,address from select sum amount by name,settlement,address from .agrar.ppl where address<>`) where cnt>5;
  };

.agrar.normalize:{[]
  .agrar.settlements: update settlement_id: i from select distinct zip,settlement from .agrar.ppl;
  normalized1: delete zip,settlement from .agrar.ppl lj `zip`settlement xkey .agrar.settlements;

  .agrar.winners: update winner_id: i from select distinct name,gender,address,settlement_id from normalized1;
  normalized2: delete name,gender,address,settlement_id from normalized1 lj `name`gender`address`settlement_id xkey .agrar.winners;

  .agrar.funds: update fund_id: i from select distinct reason,program,source from normalized2;
  .agrar.wins: delete reason,program,source from normalized2 lj `reason`program`source xkey .agrar.funds;

  .agrar.save_csv["agrar_full_wins"; .agrar.ppl];
  .agrar.save_csv["agrar_settlements"; .agrar.settlements];
  .agrar.save_csv["agrar_winners"; .agrar.winners];
  .agrar.save_csv["agrar_funds"; .agrar.funds];
  .agrar.save_csv["agrar_wins"; .agrar.wins];
  };

.agrar.analyze.init:{[]
  .agrar.raw: .agrar.load_csvs[];
  .agrar.firms: .agrar.load_firms[];
  .agrar.ppl: .agrar.load_individuals[0];

  .agrar.analyze.felcsut[];
  .agrar.analyze.tiborcz[];
  .agrar.analyze.big_wins[];
  };

if[`RUN=`$.z.x[0];
  .agrar.analyze.init[];
  ];
