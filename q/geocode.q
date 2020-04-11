\c 25 180
\p 8848

.geocode.dir: .agrar.root,"/../geocode/";

.geocode.save_csv:{[cnt;data]
  (hsym `$.geocode.dir,"agrar_raw_",string[cnt],".csv") 0: "," 0: data;
  };

.geocode.split:{[dataset]
  unique_addresses: select distinct zip,settlement,address from dataset;
  .agrar.log "splitting unique addresses ",string[count unique_addresses]," to smaller chunks";
  .geocode.distinct_addresses: update query: {"+" sv string x,y,z}'[zip;settlement;address] from unique_addresses;
  splitTables: ([] tbls: 0N 2499 # .geocode.distinct_addresses);
  tmp: select split: .geocode.save_csv'[i;tbls] from splitTables;
  .agrar.log "csvs saved: ", string count tmp;
  };

.geocode.init_pre:{[]
  .agrar.raw: .agrar.load_csvs[];
  .geocode.split[.agrar.raw];
  };

if[`GEOCODE_PRE=`$.z.x[0];
  .geocode.init_pre[];
  ];
