\c 25 180
\p 8848

system "l utils.q";
system "l scores.q";

.agrar.analyze.tiborcz:{[]
  raw_tiborcz: select from .agrar.ppl where upper[name] like "*TIBORCZ*";
  overview: select count i, sum amount by name,zip,address from raw_tiborcz;
  yearly_wins: select sum amount by year,source from raw_tiborcz;
  avg_wins: `avg_win xdesc update avg_win:amt%db from select amt: sum amount,db: count i by address from raw_tiborcz;
  };

.agrar.analyze.felcsut:{[]
  felcsut: select from .agrar.ppl where zip=8086;
  big_wins: `amount xdesc select count i, sum amount by name, address from felcsut;
  };

.agrar.analyze.big_wins:{
  ppl_wins: `avg_amt xdesc update avg_amt: amount%x from select sum amount, count i by city,zip from .agrar.ppl;
  firm_wins: `avg_amt xdesc update avg_amt: amount%x from select sum amount, count i by city,zip from .agrar.firms;
  };

.agrar.analyze.init:{[]
  .agrar.raw: .agrar.load_csvs[];
  .agrar.firms: .agrar.load_firms[];
  .agrar.ppl: .agrar.load_individuals[];
  };

if[`RUN=`$.z.x[0];
  .agrar.analyze.init[];
  ];
