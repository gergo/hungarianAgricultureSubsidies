\c 25 180
\p 8848

system "l scores.q";

.geocode.dir: .agrar.root,"/../geocode/";

.geocode.save_csv:{[cnt;data]
  (hsym `$.geocode.dir,"agrar_raw_",string[cnt],".csv") 0: "," 0: data;
  };

.geocode.split:{[]
  unique_addresses: select distinct zip,settlement,address from .agrar.raw;
  .agrar.log "splitting unique addresses ",string[count unique_addresses]," to smaller chunks";
  .geocode.distinct_addresses: update query: {"+" sv string x,y,z}'[zip;settlement;address] from unique_addresses;
  splitTables: ([] tbls: 0N 2499 # .geocode.distinct_addresses);
  tmp: select split: .geocode.save_csv'[i;tbls] from splitTables;
  .agrar.log "csvs saved: ", string count tmp;
  };

.geocode.init:{[]
  .agrar.raw: .agrar.load_csvs[];
  .agrar.firms: .agrar.load_firms[];
  .agrar.ppl: .agrar.load_individuals[0];
  };

if[`RUN=`$.z.x[0];
  .geocode.init[];
  ];
