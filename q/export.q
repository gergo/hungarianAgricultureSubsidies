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

.agrar.export.init:{[]
  // load raw data and it to split firms and individuals
  .agrar.raw: .agrar.load_csvs[];
  .agrar.firms: .agrar.load_firms[];
  .agrar.ppl: .agrar.load_individuals[0];

  // join geocoded addresses
  processed_addresses: `zip`settlement`address xkey select distinct zip,settlement,address,formatted_address,postcode,latitude,longitude from processed where status=`OK;
  .agrar.raw1: .agrar.raw lj processed_addresses;

  // Budapest zip overrides
  .agrar.zip_overrides: .agrar.create_zip_overrides[.agrar.raw];
  .agrar.raw2: update zip_mod: zip ^ postcode ^ .agrar.zip_overrides[zip] ^ .agrar.zip_overrides[postcode] from .agrar.raw1;

  .agrar.settlement_parts: .ksh.process_settlements_parts_file[];
  .agrar.settlements: .ksh.process_settlements_file[];
  };

if[`EXPORT=`$.z.x[0];
  .agrar.export.init[];
  ];
