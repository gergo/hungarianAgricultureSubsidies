.agrar.root: raze system "pwd";
.agrar.input: .agrar.root,"/../input/csv/";
.agrar.output: .agrar.root,"/../output/";
.agrar.names_dl: .agrar.root,"/../input/names/";
.agrar.names_url: "http://www.nytud.mta.hu/oszt/nyelvmuvelo/utonevek/";

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
  a2: .agrar.remove_street[a1];
  a3: .agrar.remove_spaces[a2];
  `$ upper a3
  };

///////////////////
// CSV utils
///////////////////
.agrar.save_csv:{[name;data]
  (hsym `$.agrar.output,name,".csv") 0: "," 0: data;
  };

.agrar.process_file:{[f]
  yr: `$ ssr[;".csv";""] ssr[f;.agrar.input,"utf8_";""];
  .agrar.log "  processing raw data for ", string yr;
  t: ("SISSSSSJ";enlist";")0:`$f;
  t: `name`zip`settlement`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
  };

.agrar.load_csvs:{[]
  if[.agrar.raw_loaded;:.agrar.raw];
  .agrar.log "loading raw CSVs";
  files: system "ls ",.agrar.input, "utf8_*csv";
  raw_data: raze .agrar.process_file each files;
  .agrar.log "raw files loaded";

  raw_data: update name_parts:{count " " vs string x}'[name] from update name:{`$ ssr[string[x];"  ";" "]}'[name] from raw_data;
  raw_data: update is_firm:1b from raw_data where name_parts>5;
  firm_keywords: {"*",x,"*"} each upper ("BT";"KFT";"Alapítvány";"Egyesület";"ZRT";"VÁLLALAT";"Iroda";"Önkormányzat";
    "Község";"Társulat";"Szövetkezet";"Asztaltársaság";"Vadásztársaság";"Intézmény";"Társulás";"Közösség";"Központ";
    "Társaság";"szolgálat";"Plébánia";"Szervezet";"Szövetség";"Sportklub";"Igazgatóság";"Intézet";"Klub";"Minisztérium";
    "Baráti köre";"llamkincst";"Egyetem";"hivatal";"Zöldség-Gyümölcs";"Kfc";"Tsz";"birtok";"Pincészet";"Egyéni cég";
    "Kkt.";"Baráti Kör"; "Egyesülés";"Gazdakör";"Olvasókör";"Club";"Társegyház";"Szerzetesrend";"Egyház";"Lelkészség";
    "Gazdaság";"Rt.";"Gyülekezet";"Erdőszöv";"Lovas Kör";"Ipartestület";"Nőegylet";"Polgárőrség";"Vadászegylet";
    "Fióktelepe";"Baromfi";"Hegypásztor Kör";"és vidéke";"TÉSZ";"Sport Kör";"Nővérek";"Sportkör";"Egylet";"Iskola";
    "Erdőgazdálkodás";"Faiskola";"Kórház";"Múzeum";"Zarándokház";"Olvsdó kör";"Agrárkamara");
  raw_data: update is_firm:1b from raw_data where any upper[name] like/: firm_keywords;

  land_based_categories: `$("Területalapú támogatás";"Zöldítés támogatás igénylése");
  raw_data: update land_based: 1b from raw_data where reason in land_based_categories;
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

  raw: update gender: .agrar.determine_gender'[name],address: .agrar.normalize_address'[address] from data;
  .agrar.log "number of individual wins: ", string count raw;
  delete is_firm,name_parts from raw
  };

.agrar.load_firms:{[]
  .agrar.log "Loading firms wins";
  firms: select from .agrar.load_csvs[] where is_firm;
  .agrar.log "number of firm wins: ", string count firms;
  firms
  }

.agrar.download_names:{[name]
  data: @[system;
    "curl -f ",.agrar.names_url,name," | iconv -f \"ISO-8859-2//IGNORE\" -t \"UTF-8\"";
    {[nm;error]
      show error;
      :system "cat ",.agrar.names_dl,nm,".txt";
      }[name;]
    ];
  `$ 1 _ data
  };

.agrar.log:{[msg]
  show string[.z.T],": ",msg;
  };