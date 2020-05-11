.agrar.root: raze system "pwd";
.agrar.input: .agrar.root,"/../input/csv/";
.agrar.output: .agrar.root,"/../output/";
.agrar.names_dl: .agrar.root,"/../input/names/";
.agrar.names_url: "http://www.nytud.mta.hu/oszt/nyelvmuvelo/utonevek/";

.agrar.log:{[msg]
  show string[.z.T],": ",msg;
  };

.agrar.download_names:{[name]
  .agrar.log "loading names: ", name;
  data: @[system;
    "cat ",.agrar.names_dl,name,".txt";
    {[nm;error]
      show error;
      :system "curl -f ",.agrar.names_url,nm," | iconv -f \"ISO-8859-2//IGNORE\" -t \"UTF-8\" | sed -e 's/.* -- //g'";
      }[name;]
    ];
  `$data
  };

.agrar.male_names: .agrar.download_names "osszesffi";
.agrar.female_names: .agrar.download_names "osszesnoi";
.agrar.given_names: .agrar.female_names,.agrar.male_names;
.agrar.remove_names: `$("Dr.";"dr.";"Dr";"dr";"néhai";"Néhai");

.agrar.raw_loaded:0b;

///////////////////
// Data cleaning
///////////////////
.agrar.remove_last_dot:{[addr]
  last_char: last addr;
  $["."=last_char;
  :-1 _ addr;
  :addr];
  };

.agrar.remove_spaces:{[str]
  ssr[;"  ";" "]/[str]
  };

.agrar.remove_street:{[addr]
  ssr[;"Utca";"utca"] ssr[;"\303\272t";"utca"] addr
  };

.agrar.normalize_address:{[address]
  a: string address;
  a1: .agrar.remove_last_dot[a];
  `$.agrar.remove_spaces[a1]
  };

.agrar.fix_missing_zips:{[data]
  missing_address: select from data where zip=0N;
  distinct_winners: select distinct name,zip from data;
  name_counts: select cnt: count i by name from distinct_winners;
  can_fix: exec name from name_counts where cnt=2,name in (exec distinct name from missing_address);
  no_change: update addr_fixed: 0b from select from data where zip<>0N;
  to_fix: select from data where zip=0N,name in can_fix;
  cant_fix: select from data where zip=0N,not name in can_fix;

  // save records that don't have address
  (`$"no_address.csv") 0: "," 0: cant_fix;
  .agrar.log "address cannot be fixed for sum amount of: ",string[exec sum amount from cant_fix],". Dropping records.";

  // take first address by zip for each winner and use that for the manual override
  addr_to_update: `name xkey select from
    (select name,zip,settlement,address from data where name in can_fix,zip<>0N)
    where ({x in 1#x};i) fby zip;
  fixed: update addr_fixed: 1b from to_fix lj addr_to_update;
  .agrar.log "address fixed for sum amount of: ", string[exec sum amount from fixed];
  no_change,fixed
  };

///////////////////
// CSV utils
///////////////////
.agrar.save_csv:{[name;data]
  file: .agrar.output,name,".csv";
  .agrar.log "Saving csv: ",file;
  (hsym `$file) 0: "," 0: data;
  };

.agrar.process_file:{[f]
  yr: `$ ssr[;".csv";""] ssr[f;.agrar.input,"utf8_";""];
  .agrar.log "  processing raw data for ", string yr;
  t: ("SISSSSSJ";enlist";")0:`$f;
  t: `name`zip`settlement`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
  };

.agrar.capitalize:{[word]
  (upper 1 # word),lower 1 _ word
  };

.agrar.remove_whitespace:{[word]
  ssr[string[word];"  ";" "]
  }

.agrar.fix_name:{[nm]
  `$ " " sv .agrar.capitalize each " " vs .agrar.remove_whitespace nm
  };

.agrar.load_csvs:{[]
  if[.agrar.raw_loaded;:.agrar.raw];
  .agrar.log "loading raw CSVs";
  files: system "ls ",.agrar.input, "utf8_*csv";
  raw_data: raze .agrar.process_file each files;
  .agrar.log "raw files loaded";

  raw_data: update name:.agrar.fix_name'[name] from raw_data;
  raw_data: update name_parts:{count " " vs string x}'[name] from raw_data;

  raw_data: update is_firm:1b from raw_data where name_parts>5;
  .agrar.log "marking firms based on keywords";
  firm_keywords: {"*",x,"*"} each upper ("BT";"KFT";"Alapítvány";"Egyesület";"ZRT";"VÁLLALAT";"Iroda";"Önkormányzat";
    "Község";"Társulat";"Szövetkezet";"Asztaltársaság";"Vadásztársaság";"Intézmény";"Társulás";"Közösség";"Központ";
    "Társaság";"szolgálat";"Plébánia";"Szervezet";"Szövetség";"Sportklub";"Igazgatóság";"Intézet";"Klub";"Minisztérium";
    "Baráti köre";"llamkincst";"Egyetem";"hivatal";"Zöldség-Gyümölcs";"Kfc";"Tsz";"birtok";"Pincészet";"Egyéni cég";
    "Kkt.";"Baráti Kör"; "Egyesülés";"Gazdakör";"Olvasókör";"Club";"Társegyház";"Szerzetesrend";"Egyház";"Lelkészség";
    "Gazdaság";"Rt.";"Gyülekezet";"Erdőszöv";"Lovas Kör";"Ipartestület";"Nőegylet";"Polgárőrség";"Vadászegylet";
    "Fióktelepe";"Baromfi";"Hegypásztor Kör";"és vidéke";"TÉSZ";"Sport Kör";"Nővérek";"Sportkör";"Egylet";"Iskola";
    "Erdőgazdálkodás";"Faiskola";"Kórház";"Múzeum";"Zarándokház";"Olvsdó kör";"Agrárkamara";"Agrár kamara";"Állami";
    "GAMESZ";"Testület";"Apostoli Exarchátus";"Parókia";"Gondnokság";"Szakképzési";"barátok Kör";" Megyei ";
    "Testgyakorlók Kör";"Megyei Jogú";"Városgondnoksága");
  raw_data: update is_firm:1b from raw_data where any upper[name] like/: firm_keywords;

  .agrar.log "marking land-based wins";
  land_based_categories: `$("Területalapú támogatás";"Zöldítés támogatás igénylése");
  raw_data: update land_based: 1b from raw_data where reason in land_based_categories;
  .agrar.log "determinig gender of winners";
  raw_data: update gender: .agrar.determine_gender'[name] from raw_data where not is_firm;
  .agrar.log "normalize addresses";
  raw_data: update address: .agrar.normalize_address'[address] from raw_data;

  raw_data: .agrar.fix_missing_zips[raw_data];
  .agrar.raw: raw_data;
  .agrar.raw_loaded: 1b;
  .agrar.raw
  };

.agrar.determine_gender:{[name]
  n: string name;
  np: (`$ " " vs n);
  if[any (1 _ np) in .agrar.male_names; :`male;];
  if[any (1 _ np) in .agrar.female_names; :`female;];

  nm: " " sv string (`$ " " vs n) except .agrar.remove_names;
  if[nm like "*né"; :`female;];

  :`unknown;
  };

.agrar.load_individuals:{[cutoff]
  .agrar.log "Loading individual wins";
  raw_data: .agrar.load_csvs[];
  raw_data: select from raw_data where not is_firm;
  data: delete from raw_data where abs[amount] < cutoff;
  data: delete from data where name=`;
  .agrar.log "firms and small amounts removed";
  .agrar.log "number of individual wins: ", string count data;
  delete is_firm,name_parts from data
  };

.agrar.create_bp_zip_key:{[dataset]
  t:([] zip: exec distinct zip from dataset where string[zip] like "1*");
  t1: update zip_key:{ "I"$(-1 _ string[x]),"0"}'[zip] from t
  };

oj:{
  lxy:0!lj[x;y];                  // Left join (plus remove keys)
  lyx:(cols lxy) xcols 0!lj[y;x]; // Right join (plus remove keys and prepare cols order for union)
  (cols key x) lxy union lyx      // Union (plus retrieve keys)
  };

.agrar.assert:{[testFn;input;errorMsg;successMsg]
  $[testFn input;
    [
      .agrar.log[errorMsg];
      show input;
    ];
    [
      .agrar.log[successMsg];
    ]
  ];
  };
