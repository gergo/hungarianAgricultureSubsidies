\c 25 180
\p 8848

system "l ../q/utils.q";

.geocode.dir: .agrar.root,"/../geocode/";

.geocode.process_json_response:{[t]
  t: update result:{.j.k ssr[;"True";"true"] ssr[;"False";"false"] ssr[;"'";"\""] string x}'[response] from t;
  t
  };

.geocode.process_files_raw:{[]
  .agrar.log "Loading geo-coded files";
  files: system "ls ",.geocode.dir,"agrar_output_*.csv";
  update index:i from raze .geocode.process_full_file each files
  };

// Load an individual csv with geo-coded addresses
.geocode.load_geocoded_addresses:{[]
  raw: .geocode.load_clean[];
  // remove probable data errors
  raw: delete from raw where not formatted_address like "*Hungary";
  raw: select from raw where accuracy in `ROOFTOP`RANGE_INTERPOLATED;
  raw: delete from raw where postcode<>zip;
  raw: update formatted_address: {[a;p;s]`$ ssr[;string[s],", ";""]ssr[;", ",string[p]," Hungary";""] string a}'[geocoded_address;postcode;settlement] from update geocoded_address: formatted_address from raw;
  raw
  };

.geocode.process_full_file:{[f]
  .agrar.log "  processing ", f;
  t: ("ISFFSSSISISSISSS";enlist",")0:`$f;
  t
  };

.geocode.load_clean:{[]
  f: .geocode.dir,"geocoded_clean.csv";
  .agrar.log "  processing ", f;
  t: ("ISFFSISISSI";enlist",")0: system "unzip -c ",f," | sed -e '1,3d'";
  t
  };

// Data preparation for geo-coding
.geocode.save_csv:{[cnt;data]
  (hsym `$.geocode.dir,"agrar_raw_",string[cnt],".csv") 0: "," 0: data;
  };

.geocode.split:{[dataset]
  unique_addresses: select distinct zip,settlement,address from dataset;
  .agrar.log "splitting unique addresses ",string[count unique_addresses]," to smaller chunks";
  .geocode.distinct_addresses: update query: {"+" sv string x,y,z}'[address;settlement;zip] from unique_addresses;
  splitTables: ([] tbls: 0N 2499 # .geocode.distinct_addresses);
  tmp: select split: .geocode.save_csv'[i;tbls] from splitTables;
  .agrar.log "csvs saved: ", string count tmp;
  };

.geocode.get_unprocessed_addresses:{[addresses]
  // select unique addresses
  unique_addresses: select distinct zip,settlement,address from addresses;

  // load addresses that were already processed for geocoding
  processed: .geocode.load_geocoded_addresses[];
  processed_addresses: `zip`settlement`address xkey select distinct zip,settlement,address,status from processed where status=`OK;

  // delete addresses that were already successfully geocoded
  delete from unique_addresses where ([] zip;settlement;address) in key processed_addresses
  };

.geocode.save_all_processed:{[]
  (hsym `$.geocode.dir,"agrar_output_all.csv") 0: "," 0: .geocode.process_files_raw[];
  };

.geocode.save_clean_processed:{[]
  raw: .geocode.process_files_raw[];
  raw: select index,formatted_address,latitude,longitude,accuracy,postcode,status,zip,settlement,address,number_of_results from raw;
  raw: update index:i from raw;
  (hsym `$.geocode.dir,"geocoded_clean.csv") 0: "," 0: raw;
  };

.geocode.init_pre:{[]
  .agrar.raw: .agrar.load_csvs[];
  };

if[`GEOCODE_PRE=`$.z.x[0];
  .geocode.init_pre[];
  unprocessed: .geocode.get_unprocessed_addresses[.agrar.raw];
  .geocode.split[unprocessed];
  ];
