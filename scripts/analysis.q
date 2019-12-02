\c 25 180
\p 8848

system "l utils.q";
system "l create_network.q";

.agrar.analyze.tiborcz:{[]
  .tiborcz.raw: select from .agrar.ppl where upper[name] like "*TIBORCZ*";
  .tiborcz.overview: select count i, sum amount by name,zip,address from .tiborcz.raw;
  .tiborcz.yearly_wins: select sum amount by year from .tiborcz.raw;
  .tiborcz.avg_wins: `avg_win xdesc update avg_win:amt%db from select amt: sum amount,db: count i by address from .tiborcz.raw;
  .agrar.save_csv["tiborcz_wins";.tiborcz.yearly_wins];
  };

.agrar.analyze.felcsut:{[]
  // Felcsut and neighboring towns
  .felcsut.raw: select from .agrar.ppl where zip in (8086;8087;2063;2066;2060;2065;2091);
  .felcsut.big_wins: `amount xdesc select count i, sum amount by name, address from .felcsut.raw;
  .felcsut.compact: .agrar.create_compact[.felcsut.raw];
  .felcsut.compact: update city_addr:{`$ string[x]," ",string[y]}'[city;address] from .felcsut.compact;
  .felcsut.network: .agrar.create_network_full[.felcsut.compact];

  .felcsut.avg_wins: `avg_win xdesc update avg_win:amt%db from select amt: sum amount,db: count i by name,city,address from .felcsut.raw;

  .felcsut.non_zero: select name1,city1,address1,name2,city2,address2,score from (update zero_one: {$[x<3;:0;:1]}'[score] from .felcsut.network) where zero_one=1;
  .agrar.save_csv["felcsut_network"; .felcsut.non_zero];
  .agrar.save_csv["felcsut_avg_wins"; .felcsut.avg_wins];
  };

.agrar.analyze.big_wins:{[]
  // Are there individuals and firms that share address?
  .misc.same_addresses: (`zip`city`address xkey .agrar.firms) ij `zip`city`address xkey .agrar.ppl;

  // Residents of which town won the largest amount of subsidies - order by average wins
  .misc.ppl_wins_avg: `avg_amt xdesc update avg_amt: amount%wins from select sum amount, wins: count i by city,zip from .agrar.ppl;

  // Firms of which town won the most money - order by average amount
  .misc.firm_wins: `avg_amt xdesc update avg_amt: amount%wins from select sum amount, wins: count i by city,zip from .agrar.firms;

  // Which individuals won the most in agricultural subsidies
  .misc.ppl_wins_max: () xkey `amount xdesc select sum amount,count i by name,city,address from .agrar.ppl;
  };

.agrar.analyze.init:{[]
  .agrar.raw: .agrar.load_csvs[];
  .agrar.firms: .agrar.load_firms[];
  .agrar.ppl: .agrar.load_individuals[];
  };

if[`RUN=`$.z.x[0];
  .agrar.analyze.init[];
  ];
