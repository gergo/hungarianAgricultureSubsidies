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

.agrar.init:{[]
  // load settlement data
  settlements: select settlement:helyseg,ksh_id:ksh_kod,settlement_type:tipus,county:megye,district:jaras_nev,district_code:jaras_kod,
    county_capital:megyeszekhely,area:terulet,population:nepesseg,homes:lakasok from .ksh.process_settlements_file[];

  // load agricultural subsidies
  raw_subsidies_0: .agrar.load_csvs[];

  // join geocoded addresses to subsidies
  processed_addresses: .geocode.process_files[];
  clean_addresses: `zip`settlement`address xkey select distinct zip,settlement,address,formatted_address,postcode,latitude,longitude
    from processed_addresses where status=`OK,number_of_results=1;
  raw_subsidies_1_with_clean_addresses: raw_subsidies_0 lj clean_addresses;

  // add Budapest zip overrides to subsidies
  zip_overrides: .agrar.create_zip_overrides[raw_subsidies_0];
  raw_subsidies_2_with_zip_mod: update zip_mod: zip ^ postcode ^ zip_overrides[zip] ^ zip_overrides[postcode] from raw_subsidies_1_with_clean_addresses;

  // Budapest district map
  bp_district_names: update zip_mod:{"I"$"1",(ssr[;". ker.";""] ssr[;"Budapest ";""] string[x]),"0"}'[name] from select from settlements where name like "Budapest *";
  bp_district_name_map: bp_district_names[`zip_mod]!bp_district_names[`name];
  raw_subsidies_3_with_bp_districts: update settlement_mod: settlement ^ bp_district_name_map[zip_mod] from raw_subsidies_2_with_zip_mod;

  // add zip codes to settlements
  zips_by_settlement: select distinct zip_mod by settlement_mod from raw_subsidies_3_with_bp_districts where zip_mod<>0N;
  .agrar.settlement_details: delete settlement from ungroup (update settlement_mod:settlement from settlements) lj zips_by_settlement;

  // add ksh_id to subsidies
  .agrar.full: raw_subsidies_3_with_bp_districts lj `settlement_mod xkey select distinct ksh_id,settlement_mod from .agrar.settlement_details;
  };

if[`EXPORT=`$.z.x[0];
  .agrar.init[];
  ];
