\p 8850

system "l ../q/ksh.q";
system "l ../q/geocode.q";
system "l ../q/utils.q";

.agrar.export.normalize:{[]
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

.agrar.export.load_wins:{[]
  // load raw data and it to split firms and individuals
  raw: .agrar.load_csvs[];
  // .agrar.firms: .agrar.load_firms[];
  // .agrar.ppl: .agrar.load_individuals[0];

  // join geocoded addresses
  processed: .geocode.process_files[];
  processed_addresses: `zip`settlement`address xkey select distinct zip,settlement,address,formatted_address,postcode,latitude,longitude from processed where status=`OK;
  raw1: raw lj processed_addresses;

  // Budapest zip overrides
  zip_overrides: .agrar.create_zip_overrides[raw];
  .agrar.full: update zip_mod: zip ^ postcode ^ zip_overrides[zip] ^ zip_overrides[postcode] from raw1;
  };

.agrar.export.load_settlement_data:{[]
  // load settlement data
  settlements: select name:helyseg,ksh_id:ksh_kod,settlement_type:tipus,county:megye,district:jaras_nev,district_code:jaras_kod,
    county_capital:megyeszekhely,area:terulet,population:nepesseg,homes:lakasok from .ksh.process_settlements_file[];

  // add zips
  bp_zips: select zip by ksh_id from update zip:{"I"$"1",(ssr[;". ker.";""] ssr[;"Budapest ";""] string[x]),"0"}'[name] from select name,ksh_id from settlements where name like "Budapest *";
  zips: bp_zips, select zip by ksh_id from select zip: iranyito_szam, ksh_id: ksh_kod from .ksh.process_settlements_parts_file[] where not helyseg like "Budapest*";

  .agrar.settlement_details: zips lj `ksh_id xkey select name,ksh_id,settlement_type,county,district,district_code,county_capital,area,population,homes from settlements;
  };

if[`EXPORT=`$.z.x[0];
  .agrar.export.load_wins[];
  .agrar.export.load_settlement_data[];
  ];
