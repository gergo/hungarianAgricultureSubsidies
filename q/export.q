\p 8850

system "l ../q/settlements.q";
system "l ../q/geocode.q";
system "l ../q/utils.q";
system "l ../q/elections.q";

.agrar.export.normalize:{[]
  .data.settlement_details: update settlement_id: i from delete zip_mod,settlement_mod from .data.settlement_details;

  normalized1: delete zip_mod,settlement_mod,ksh_id,zip,settlement from
    (update settlement: settlement_mod,zip:zip_mod from .data.full) lj
    `zip`settlement xkey select settlement_id,zip,settlement from .data.settlement_details;

  .data.winners: update winner_id: i from
    select distinct name,gender,address,formatted_address,is_firm,latitude,longitude,settlement_id from normalized1;
  normalized2: delete name_parts,addr_fixed,postcode,name,gender,address,formatted_address,is_firm,latitude,longitude,settlement_id from normalized1 lj
    `name`gender`address`formatted_address`is_firm`latitude`longitude`settlement_id xkey .data.winners;

  .data.funds: update fund_id: i from select distinct reason,program,source,land_based from normalized2;
  .data.wins: delete reason,program,source,land_based from normalized2 lj `reason`program`source`land_based xkey .data.funds;
  };

.agrar.export.save:{[]
  .agrar.save_csv["agrar_settlements"; .data.settlement_details];
  .agrar.save_csv["agrar_winners"; .data.winners];
  .agrar.save_csv["agrar_funds"; .data.funds];
  .agrar.save_csv["agrar_wins"; .data.wins];
  .agrar.save_csv["agrar_full"; .data.full];
  };

.agrar.export.init:{[]
  // load settlement data
  settlements: select settlement:helyseg, ksh_id:ksh_kod, settlement_type:tipus, county:megye, district:jaras_nev,
    district_code:jaras_kod, county_capital:megyeszekhely, area:terulet, population:nepesseg, homes:lakasok,
    is_capital:{3}'[i] from .ksh.process_settlements_file[];
  settlements: update is_capital:{2}'[i] from settlements where settlement=county_capital;
  settlements: update is_capital:{1}'[i] from settlements where settlement like "Budapest*";

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
  bp_district_names: update zip_mod:{"I"$"1",(ssr[;". ker.";""] ssr[;"Budapest ";""] string[x]),"0"}'[settlement] from select from settlements where settlement like "Budapest *";
  bp_district_name_map: bp_district_names[`zip_mod]!bp_district_names[`settlement];
  raw_subsidies_3_with_bp_districts: update settlement_mod: settlement ^ bp_district_name_map[zip_mod] from raw_subsidies_2_with_zip_mod;

  // add zip codes to settlements
  zips_by_settlement: select distinct zip_mod by settlement_mod from raw_subsidies_3_with_bp_districts where zip_mod<>0N;
  .data.settlement_details: update settlement:settlement_mod,zip:zip_mod from ungroup (update settlement_mod:settlement from settlements) lj zips_by_settlement;

  // add ksh_id to subsidies
  data_full: raw_subsidies_3_with_bp_districts lj `settlement_mod xkey select distinct ksh_id,settlement_mod from .data.settlement_details;
  zip_map: 1!select zip_mod: zip,ksh_id,settlement_mod: settlement from .ksh.ksh_id_zip_map[];
  .data.full: (select from data_full where ksh_id<>0N),(select from data_full where ksh_id=0N) lj zip_map;

  // settlement-level data for analysis
  .data.settlement_stats: select distinct from delete zip,settlement_id from .data.settlement_details;
  .data.win_by_settlements: 0! select sum amount by is_firm,land_based,year,ksh_id from .data.full;
};

if[`EXPORT=`$.z.x[0];
  .agrar.export.init[];
  .agrar.export.normalize[];
  // .agrar.export.save[];
  ];
