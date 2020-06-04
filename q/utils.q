.agrar.root: raze system "pwd";
.agrar.input: .agrar.root,"/../input/csv/";
.agrar.output: .agrar.root,"/../output/";
.agrar.names_dl: .agrar.root,"/../input/names/";
.agrar.names_url: "http://www.nytud.mta.hu/oszt/nyelvmuvelo/utonevek/";
.data.misc_vars: ([var_name: `symbol$()]; val: `symbol$());

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

.agrar.name_overrides:{[nm]
  `$ system "cat ",.agrar.names_dl,nm,".txt"
  };

.agrar.male_names: distinct .agrar.name_overrides["men"], .agrar.download_names["osszesffi"];
.agrar.female_names: distinct .agrar.name_overrides["women"], .agrar.download_names["osszesnoi"];
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

.agrar.fix_missing_addresses:{[data]
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

.agrar.read_file:{[f]
  yr: `$ ssr[;".csv";""] ssr[f;.agrar.input,"utf8_";""];
  .agrar.log "  processing raw data for ", string yr;
  t: ("SISSSSSJ";enlist";")0:`$f;
  t: `name`zip`settlement`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
  };

.agrar.read_2010_file:{
  .agrar.log "  processing raw data for 2010";
  t: ("SISSSSSJJS";enlist",")0:`$.agrar.input, "old_2010.csv";
  t: `name`zip`settlement`address`reason`program`source`amount`total_amount`year xcol t;
  delete total_amount from t
  };

.agrar.remove_whitespace:{[word]
  {x where not(and':)null x} word
  };

.agrar.remove_dots:{[word]
  ssr[;"-, ";" "] ssr[;" -";"-"] ssr[;"- ";"-"] ssr[;",";" "] ssr[;".";""] word
  };

.agrar.remove_apostrophes:{[word]
  ssr[word;"\\\"";""]
  };

.agrar.lowerChars: ("áéíóöőúüű");
.agrar.upperChars: ("ÁÉÍÓÖŐÚÜŰ");
.agrar.toUpperMap:(.agrar.lowerChars!.agrar.upperChars);
.agrar.upper:{[w]upper w^'(.agrar.toUpperMap)@/:w};
.agrar.lower:{[w]lower w^'(.agrar.upperChars!.agrar.lowerChars)@/:w};
.agrar.capitalize:{[word]
  word: .agrar.lower word;
  startsWithSpecialChar: (2#word) in 0N 2 # .agrar.lowerChars;
  $[startsWithSpecialChar;
    :(.agrar.toUpperMap 2#word), 2_word;
    :(upper 1 # word),1_word]
  };

.agrar.fix_name:{[nm]
  `$ " " sv .agrar.capitalize each string (`$ raze ("-" vs) each " " vs .agrar.remove_whitespace .agrar.remove_dots .agrar.remove_apostrophes string nm) except `
  };

.agrar.process_csv:{[tbl]
  .agrar.log "Processing  - ", raze string exec year from 1 # tbl;
  .agrar.log "Records:  - ", string count tbl;

  tbl: delete from tbl where amount<0;
  .agrar.log "<0 amounts dropped - ", string count tbl;

  dropping: raze exec sum amount from tbl where name=`,address=`;
  tbl: delete from tbl where name=`,address=`;
  .agrar.log "records without name and address dropped totaling: ", raze string dropping;

  .agrar.log "unique names: ", string count select distinct name from tbl;
  tbl: update name:.agrar.fix_name'[name] from tbl;
  .agrar.log "Trivial name errors fixed; unique names: ", string count select distinct name from tbl;

  tbl: update name_parts:{count " " vs string x}'[name] from tbl;

  tbl: update is_firm:1b from tbl where name_parts>8;
  .agrar.log "marking firms based on keywords";
  raw_firm_keywords: read0 hsym `$"../input/names/firm_keywords.txt";
  firm_keywords: {"*",x,"*"} each .agrar.upper each raw_firm_keywords;

  // keyword-based matching is quite slow so only run on rows we have not categorized yet
  known_firms: select from tbl where is_firm;
  tbl: delete from tbl where is_firm;
  tbl: update upper_name: {`$ .agrar.upper string x}'[name] from tbl;
  tbl: known_firms,delete upper_name from update is_firm:1b from tbl where any upper_name like/: firm_keywords;

  .agrar.log "marking land-based wins";
  land_based_categories: `$("Területalapú támogatás";"Zöldítés támogatás igénylése");
  tbl: update land_based: 1b from tbl where reason in land_based_categories;
  .agrar.log "determinig gender of winners";
  tbl: update gender: .agrar.determine_gender'[name] from tbl where not is_firm;
  .agrar.log "normalize addresses";
  tbl: update address: .agrar.normalize_address'[address] from tbl;
  tbl
  };

.agrar.load_vars:{[]
  data_2010: .agrar.read_2010_file[];
  files: system "ls ",.agrar.input, "utf8_*csv";
  raw_data: data_2010, raze .agrar.read_file each files;
  `.data.misc_vars insert (`raw_entity_count; `$ string count select distinct name,zip,settlement,address from raw_data);
  `.data.misc_vars insert (`clean_entity_count; `$ string count select distinct name,zip,settlement,address from .data.full);
  `.data.misc_vars insert (`raw_address_count; `$ string count select distinct zip,settlement,address from raw_data);
  `.data.misc_vars insert (`clean_address_count; `$ string count select distinct zip,settlement,address from .data.full);
  `.data.misc_vars insert (`total_amount; `$ string exec sum amount from .data.full);
  };

.agrar.load_csvs:{[]
  if[.agrar.raw_loaded;:.agrar.raw];
  .agrar.log "loading raw CSVs";
  files: system "ls ",.agrar.input, "utf8_*csv";
  data_2010: .agrar.process_csv .agrar.read_2010_file[];
  raw_data: data_2010, raze {.agrar.process_csv .agrar.read_file x} each files;

  raw_data: .agrar.fix_missing_addresses[raw_data];
  .agrar.raw: raw_data;
  .agrar.raw_loaded: 1b;
  .agrar.raw
  };

.agrar.determine_gender:{[name]
  n: string name;
  np: (`$ " " vs n);
  if[any (1 _ np) in .agrar.male_names; :`male;];
  if[any (1 _ np) in .agrar.female_names; :`female;];

  nm: string (`$ " " vs n) except .agrar.remove_names;
  if[any nm like "*né"; :`female;];

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

// works but very slow compared to native approach
.agrar.capitalize_py: {raze system "python -c \"print(\\\"",x,"\\\".capitalize())\""};
.agrar.upper_py:{raze system "python -c \"print(\\\"",x,"\\\".upper())\""};
.agrar.lower_py:{raze system "python -c \"print(\\\"",x,"\\\".lower())\""};
.agrar.toPythonList: {"[",("," sv "'",'x,'"'"),"]"};
.agrar.pythonUpper: {system "python -c \"print([nm.title() for nm in ",x,"])\""};
.agrar.toQList: {-1_'1_'", " vs -1_1_x};
.agrar.customUpper: {`$ .agrar.toQList first .agrar.pythonUpper .agrar.toPythonList x};
