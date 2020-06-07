\p 8850

system "l ../q/settlements.q";
system "l ../q/geocode.q";
system "l ../q/utils.q";
system "l ../q/elections.q";

.agrar.export.normalize:{[]
  .data.settlements: update settlement_id: i from distinct delete zip_mod,settlement_mod from .data.settlements;

  normalized1: delete zip_mod,settlement_mod,address_orig,address_mod,ksh_id,zip,settlement from
    (update settlement: settlement_mod,zip:zip_mod from .data.full) lj
    `zip`settlement xkey select settlement_id,zip,settlement from .data.settlements;

  .data.winners: update winner_id: i from
    select distinct name,gender,address,is_firm,latitude,longitude,settlement_id from normalized1;
  normalized2: delete name_parts,addr_fixed,postcode,name,gender,address,is_firm,latitude,longitude,settlement_id from normalized1 lj
    `name`gender`address`is_firm`latitude`longitude`settlement_id xkey .data.winners;

  .data.funds: update fund_id: i from select distinct reason,program,source,land_based from normalized2;
  .data.wins: delete reason,program,source,land_based from normalized2 lj `reason`program`source`land_based xkey .data.funds;
  };

.agrar.export.save:{[]
  .agrar.save_csv["agrar_settlements"; .data.settlements];
  .agrar.save_csv["agrar_winners"; .data.winners];
  .agrar.save_csv["agrar_funds"; .data.funds];
  .agrar.save_csv["agrar_wins"; .data.wins];
  .agrar.save_csv["agrar_full"; .data.full];

  .agrar.save_csv["settlement_stats"; .data.settlement_stats];
  .agrar.save_csv["win_by_settlements"; .data.win_by_settlements];

  .agrar.save_csv["avg_win_by_gender"; select avg_win: sum amt%count i by gender,year from (select amt: sum amount by name,settlement,zip,address,year,gender from .data.full where gender<>`unknown,not is_firm)];

  .agrar.load_vars[];
  .agrar.save_csv["misc_vars";.data.misc_vars];
  };

.agrar.export.init:{[]
  // load settlement data
  settlements: select settlement:helyseg, ksh_id:ksh_kod, settlement_type:tipus, county:megye, district:jaras_nev,
    district_code:jaras_kod, district_capital:jaras_szekhely, area:terulet, population:nepesseg, homes:lakasok from .ksh.process_settlements_file[];
  county_capitals: `county xkey .ksh.county_capitals[];
  settlements: settlements lj county_capitals;

  settlements: update settlement_type:`$"járás székhely" from settlements where settlement=district_capital;
  settlements: update settlement_type:`$"megyeszékhely" from settlements where settlement=`$"megyeszékhely, megyei jogú város";
  settlements: update settlement_type:`$"megyeszékhely" from settlements where settlement=county_capital;
  settlements: update settlement_type:`$"Budapest"  from settlements where settlement like "Budapest*";
  settlements: delete from settlements where settlement=`Budapest;

  // load agricultural subsidies
  raw_subsidies_0: .agrar.load_csvs[];

  // join geocoded addresses to subsidies
  processed_addresses: .geocode.load_geocoded_addresses[];
  clean_addresses: `zip`settlement`address xkey
    select distinct zip,settlement,address,formatted_address,postcode,latitude,longitude
    from processed_addresses where status=`OK,number_of_results=1;
  raw_subsidies_1_with_clean_addresses: raw_subsidies_0 lj clean_addresses;

  // add zip codes to settlements
  budapest_zips: distinct select from raw_subsidies_1_with_clean_addresses where settlement like "*Budapest*";
  budapest_zips: .agrar.create_bp_zip_key[budapest_zips];
  bp_district_names: `zip_key xkey update zip_key:{"I"$"1",(ssr[;". ker.";""] ssr[;"Budapest ";""] string[x]),"0"}'[settlement] from select from settlements where settlement like "Budapest *";
  budapest_districts: delete zip_key from budapest_zips lj bp_district_names;
  bp_district_name_map: budapest_districts[`zip]!budapest_districts[`settlement];
  settlement_overrides: select zip,settlement from .ksh.ksh_id_settlement_map[] where zip in (exec zip from (select c: count i by zip from .ksh.ksh_id_settlement_map[]) where c=1);
  settlement_override_map: settlement_overrides[`zip]!settlement_overrides[`settlement];
  settlement_part_map: .ksh.ksh_id_settlement_part_map[][`settlement_part]!.ksh.ksh_id_settlement_part_map[][`settlement];

  raw_subsidies_2_with_zip_mod: update zip_mod: zip ^ postcode,
    address_mod: address ^ formatted_address from raw_subsidies_1_with_clean_addresses;
  raw_subsidies_3_with_bp_districts: update settlement_mod: settlement ^ settlement_part_map[settlement] ^ settlement_override_map[zip_mod] ^ bp_district_name_map[zip_mod] from raw_subsidies_2_with_zip_mod;

  zips_by_settlement: select distinct zip_mod by settlement_mod from raw_subsidies_3_with_bp_districts where zip_mod<>0N;
  .data.settlement_details: distinct update settlement:settlement_mod,zip:zip_mod from ungroup (update settlement_mod:settlement from settlements) lj zips_by_settlement;

  // zip to ksh_id map
  zip_map: distinct (select distinct zip,ksh_id,settlement from .data.settlement_details),(select zip,ksh_id,settlement from budapest_districts),.ksh.ksh_id_settlement_map[];
  .data.settlements: .data.settlement_details lj `zip`settlement xkey zip_map;

  // add ksh_id to subsidies
  data_full: update address: address_orig ^ address_mod from
    update address_orig: address from raw_subsidies_3_with_bp_districts lj
    `settlement_mod`zip_mod xkey select distinct ksh_id,settlement_mod,zip_mod from .data.settlements;
  .data.full: (select from data_full where ksh_id<>0N),(select from data_full where ksh_id=0N) lj `zip`settlement xkey zip_map;

  // assert: log if there are unmapped zip codes
  unmapped: `amount xdesc select sum amount by year,zip_mod,settlement_mod from .data.full where ksh_id=0N;
  .agrar.assert[
    {0<count x};
    unmapped;
    "Unmapped zip codes! Check where they belong and add them to manual_zip_map.csv";
    "There are 0 unmapped zip codes!"
  ];

  // settlement-level data for analysis
  settlement_coordinates: select avg latitude,avg longitude by ksh_id,settlement_mod from .data.full where latitude<>0N,longitude<>0N;
  settlement_stats: delete from (select distinct from delete zip_mod,zip,settlement_id from .data.settlements) where settlement_mod=`;
  .data.settlement_stats: settlement_stats lj settlement_coordinates;
  .data.win_by_settlements: 0! select sum amount by is_firm,land_based,year,ksh_id from .data.full;
  };

.agrar.save_name_mismatch:{[]
  agrar_zips: select distinct zip,settlement from .data.full;
  ksh: .ksh.process_settlements_parts_file[];
  ksh_zips: select distinct zip:iranyito_szam,settlement:helyseg from ksh;
  ksh_zip_list: exec distinct zip from ksh_zips;
  agrar_zip_list: exec distinct zip from agrar_zips;

  select from ksh_zips where zip in ksh_zip_list except agrar_zip_list;
  select from agrar_zips where zip in agrar_zip_list except ksh_zip_list;

  settlement_name_mismatch: (select zip, ksh_settlement:settlement from ksh_zips) ij (1! select zip,agrar_settlemnt:settlement from (agrar_zips except ksh_zips) where zip in ksh_zip_list);

  .agrar.save_csv["settlement_name_mismatch";settlement_name_mismatch];
  };

.agrar.analyze:{[]
  .data.ppl: select from .data.full where not is_firm;
  .data.firms: select from .data.full where is_firm;

  // Are there individuals and firms that share address?
  .misc.same_addresses: `ksh_id`zip`settlement`address`total`p_amt`f_amt`p_pct`f_pct`persons`firms xcols
    update persons: {`$";" sv string x}'[persons], firms: {`$";" sv string x}'[firms] from
    update p_pct: 100-f_pct from update f_pct:`int$100*f_amt%total from update total: p_amt+f_amt from
    () xkey (select firms: distinct name, f_amt: sum amount by zip,settlement,address,ksh_id from .data.firms) ij
    `zip`settlement`address xkey select persons: distinct name, p_amt: sum amount by zip,settlement,address,ksh_id from .data.ppl;
  `.data.misc_vars insert (`total_amount_address_sharing; `$ string exec sum total from .misc.same_addresses);
  .agrar.save_csv["misc_same_addresses";.misc.same_addresses];

  // Residents of which town won the largest amount of subsidies - order by average wins
  .misc.ppl_wins_avg: `avg_amt xdesc update avg_amt: amount%wins from select sum amount, wins: count i by settlement, zip from .data.ppl;

  // Firms of which town won the most money - order by average amount
  .misc.firm_wins: `avg_amt xdesc update avg_amt: amount%wins from select sum amount, wins: count i by settlement,zip from .data.firms;

  // Which individuals won the most in agricultural subsidies
  max_ppl_wins: select from (
    () xkey update name:{[nm]`$ (1#(" " vs string nm)[0]),". "," " sv 1_(" " vs string nm)}'[name] from
      (select total: sum amount,cnt: count i by name,settlement,address,zip,ksh_id,latitude,longitude from .data.ppl))
    where total>500000000;
  .misc.ppl_wins_max: () xkey `total xdesc (select from max_ppl_wins where latitude<>0N,longitude<>0N),
    (select from max_ppl_wins where (latitude=0N) or longitude=0N) lj
    1! select ksh_id,latitude,longitude from .data.settlement_stats;
  .agrar.save_csv["misc_ppl_wins_max";.misc.ppl_wins_max];

  max_ppl_wins_by_address: update ppl_cat:{$[x<2;`$"1";$[x<4;`$"2-3";$[x<8;`$"4-7";`$"8+"]]]}'[ppl] from
    select from
      (select ppl: count i, total: sum amount by settlement,address,zip,ksh_id,latitude,longitude from
        (select sum amount by name,settlement,address,zip,ksh_id,latitude,longitude from .data.ppl where address<>`))
    where total>500000000;
  .misc.ppl_wins_max_by_address: () xkey `total xdesc (select from max_ppl_wins_by_address where latitude<>0N,longitude<>0N),
  (select from max_ppl_wins_by_address where (latitude=0n) or longitude=0n) lj
  1! select ksh_id,latitude,longitude from .data.settlement_stats;
  .agrar.save_csv["misc_ppl_wins_max_by_address";.misc.ppl_wins_max_by_address];

  // Which institutions won the most in agricultural subsidies - threshold of 1 bn
  max_firm_wins: select from
    (select total: sum amount,cnt: count i by name,settlement,address,zip,ksh_id,latitude,longitude from .data.firms)
  where total>1000000000;
  .misc.firm_wins_max: () xkey `total xdesc (select from max_firm_wins where latitude<>0N,longitude<>0N),
  (select from max_firm_wins where (latitude=0N) or longitude=0N) lj
  1! select ksh_id,latitude,longitude from .data.settlement_stats;
  .agrar.save_csv["misc_firm_wins_max";.misc.firm_wins_max];

  max_firm_wins_by_address: update cat:{$[x<2;`$"1";$[x<4;`$"2-3";$[x<8;`$"4-7";`$"8+"]]]}'[firms] from
  select from
    (select firms: count i, total: sum amount by settlement,address,zip,ksh_id,latitude,longitude from
      (select sum amount by name,settlement,address,zip,ksh_id,latitude,longitude from .data.firms where address<>`))
    where total>1000000000;
  .misc.firm_wins_max_by_address: () xkey `total xdesc (select from max_firm_wins_by_address where latitude<>0N,longitude<>0N),
  (select from max_firm_wins_by_address where (latitude=0n) or longitude=0n) lj
  1! select ksh_id,latitude,longitude from .data.settlement_stats;
  .agrar.save_csv["misc_firm_wins_max_by_address";.misc.firm_wins_max_by_address];

  // which households contain the most winners (along with the amounts)
  .misc.single_household: () xkey update name: {";" sv string x}'[name] from (select from
    (`cnt xdesc select name, cnt: count i,sum amount by settlement,address,zip from
      select sum amount by name,settlement,address,zip from .data.ppl where address<>`)
    where cnt>5);
  .agrar.save_csv["misc_single_household";.misc.single_household];

  .misc.yearly_win_by_settlement: () xkey
    (select winners: count name,sum amount by settlement,ksh_id,year,is_firm,land_based from
      (select sum amount by name,settlement,address,ksh_id,year,is_firm,land_based from .data.full));
  .agrar.save_csv["misc_yearly_win_by_settlement";.misc.yearly_win_by_settlement];
  };

// function to generate yearly diff based on dynamic constraints
// .agrar.yearly_diffs[tbl:.data.full;constraint:(`land_based;(=;`zip;8086));limit:1000000;records:1]
.agrar.yearly_diffs:{[tbl;constraint;limit;records]
  yearly_amounts: ?[tbl;constraint;(`name`addr`year`zip`settlement)!(`name;(^;`address;`formatted_address);`year;`zip;`settlement);(enlist `amount)!enlist(sum;`amount)];
  winners: select distinct name,addr,zip,settlement from yearly_amounts;
  zeros: winners cross update amount:0 from select distinct year from yearly_amounts;
  diffs: update diff: deltas amount by addr,zip,settlement from select names: distinct name,sum amount by addr,zip,settlement,year from zeros, () xkey yearly_amounts;
  diffs: delete from diffs where year = `$ string min "I"$ string exec distinct year from diffs;
  diffs: select from diffs where limit<abs diff;
  ret: () xkey (select from (`diff xdesc diffs) where ({[r;x]x in r#x}[records;];i) fby ([]zip;year)),select from (`diff xasc diffs) where ({[r;x]x in r#x}[records;];i) fby ([]zip;year);
  xcols[`addr`zip`settlement`year`amount`diff;ret]
  };

if[`EXPORT=`$.z.x[0];
  .agrar.export.init[];
  .agrar.export.normalize[];
  .agrar.analyze[];
  .agrar.export.save[];
  ];

