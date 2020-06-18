\c 25 180
\p 8848

system "l ../q/utils.q";
system "l ../q/create_network.q";

.agrar.analyze.tiborcz:{[]
  .tiborcz.raw: select from .data.ppl where upper[name] like "*TIBORCZ*";
  .tiborcz.overview: select count i, sum amount by name,zip,address from .tiborcz.raw;
  .tiborcz.yearly_wins: select sum amount by year from .tiborcz.raw;
  .tiborcz.avg_wins: `avg_win xdesc update avg_win:amt%cnt from select amt: sum amount,cnt: count i by address from .tiborcz.raw;
  .agrar.save_csv["tiborcz_wins";.tiborcz.yearly_wins];
  };

.agrar.analyze.felcsut:{[]
  // Felcsut and neighboring towns
  .felcsut.raw: select from .data.ppl where zip in (8086;8087;2063;2066;2060;2065;2091);
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

.agrar.analyze.init:{[]
  .dara.raw: .agrar.load_csvs[];
  .agrar.firms: select from .data.raw where is_firm;
  .data.ppl: .agrar.load_individuals[0];

  .agrar.analyze.felcsut[];
  .agrar.analyze.tiborcz[];
  };

if[`ANALYSIS=`$.z.x[0];
  .agrar.analyze.init[];
  ];
