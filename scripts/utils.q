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
  show "  processing raw data for ", string yr;
  t: ("SISSSSSI";enlist";")0:`$f;
  t: `name`zip`city`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
  };

.agrar.load_csvs:{[]
  if[.agrar.raw_loaded;:.agrar.raw];
  show "loading raw CSVs";
  files: system "ls ",.agrar.input, "utf8_*csv";
  raw_data: raze .agrar.process_file each files;
  show "raw files loaded";

  raw_data: update name_parts:{count " " vs string x}'[name] from raw_data;
  raw_data: update is_firm:1b from raw_data where name_parts>5;
  firm_keywords: upper ("*BT*";"*KFT*";"*Alapítvány*";"*Egyesület*";"*ZRT*";"*VÁLLALAT*";"*Iroda*";
      "*Önkormányzat*";"*Község*";"*Társulat*";"*Szövetkezet*";"*Asztaltársaság*";"*Vadásztársaság*";
      "*Intézmény*";"*Társulás*";"*Közösség*";"*Központ*";"*Társaság*";"*szolgálat*";"*Plébánia*";
      "*Szervezet*";"*Szövetség*";"*Sportklub*";"*Igazgatóság*";"*Intézet*";"*Klub*";"*Minisztérium*";
      "*Baráti köre*";"*llamkincst*";"*Egyetem*";"*hivatal*";"*Zöldség-Gyümölcs*";"*Kfc*";"*Tsz*";
      "*birtok*";"*Pincészet*";"Egyéni cég");
  raw_data: update is_firm:1b from raw_data where any upper[name] like/: firm_keywords;
  .agrar.raw: raw_data;
  .agrar.raw_loaded: 1b;
  .agrar.raw
  };

.agrar.load_individuals:{[]
  show "Loading individual wins";
  raw_data: .agrar.load_csvs[];
  raw_data: select from raw_data where not is_firm;
  cutoff_for_win: 200000;
  data: delete from raw_data where abs[amount] < cutoff_for_win;
  data: delete reason, program from data;
  data: delete from data where name=`;
  show "firms and small amounts removed";

  raw: update address: .agrar.normalize_address'[address] from data;
  show "number of individual wins: ", string count raw;
  raw
  };

.agrar.load_firms:{[]
  show "Loading firms wins";
  firms: select from .agrar.load_csvs[] where is_firm;
  show "number of firm wins: ", string count firms;
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
