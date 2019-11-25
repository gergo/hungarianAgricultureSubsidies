\c 25 180
\p 8848

.agrar.process_file:{[f]
  yr: `$ ssr[ssr[f;.agrar.input,"utf8_";""];".csv";""];
  show "  processing raw data for ", string yr;
  t: ("SISSSSSI";enlist";")0:`$f;
  t: `name`zip`city`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
  };

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
  no_utca: ssr[addr;"[Uu]tca";""];
  no_ut: ssr[no_utca;"[Úú]t";""];
  no_ut
  };

.agrar.normalize_address:{[address]
  a: string address;
  a1: .agrar.remove_last_dot[a];
  a2: .agrar.remove_street[a1];
  a3: .agrar.remove_spaces[a2];
  `$ upper a3
  };


.agrar.load_csvs:{[]
  show "loading raw CSVs";
  files: system "ls ",.agrar.input, "utf8_*csv";
  raw_data: raze .agrar.process_file each files;
  show "raw files processed";

  data: update name_parts:{count " " vs string x}'[name] from raw_data;
  data: delete reason, program from delete from data where name_parts>5;
  data: delete from data where name=`;
  delete_list: upper ("*BT*";"*KFT*";"*Alapítvány*";"*Egyesület*";"*ZRT*";"*VÁLLALAT*";"*Önkormányzat*";"*Község*";"*Társulat*";"*Szövetkezet*";"*Asztaltársaság*";"*Vadásztársaság*";"*Intézmény*";"*Társulás*";"*Közösség*";"*Központ*";"*Társaság*";"*szolgálat*";"*Plébánia*";"*Szervezet*";"*Szövetség*";"*Sportklub*";"*Igazgatóság*";"*Intézet*";"*Klub*";"*Baráti köre*");
  data1: delete from data where amount < 1000000;
  data1: delete from data1 where any upper[name] like/: delete_list;
  show "firms and small amounts removed";

  raw: update address: .agrar.normalize_address'[address] from data1;
  show ".agrar.raw variable crated - ", string count raw;
  raw
  };

///
// Raw data is too large so we group subsidies together
.agrar.create_compact:{[raw]
  compact: select sum amount,wins: count i by name,zip,city,address from raw;
  compact: compact lj select name_count: count i by name from compact;
  compact
  }

///
// create simple network by joining entries with the same zip code
.agrar.create_network:{[compact]
  ppl1: update id: i from compact;
  ppl1: () xkey delete zip1 from update zip: zip1 from xcol[raze {`$raze string x,"1"} each cols ppl1; ppl1];

  ppl2: update id: i from compact;
  ppl2: () xkey delete zip2 from update zip: zip2 from xcol[raze {`$raze string x,"2"} each cols ppl2; ppl2];

  network: delete from ej[`zip;ppl1;ppl2] where id1>=id2;
  show "created network skeleton - ", string count network;
  network
  };

.agrar.compare_addresses:{[a1;a2]
  if[a1=a2;:10];
  a1: " " vs string a1;
  a2: " " vs string a2;
  if[1<count a1; a1: -1 _  a1];
  if[1<count a2; a2: -1 _  a2];
  if[(`$ raze a1)=(`$ raze a2);:3];
  :0;
  };

.agrar.compare_names:{[n1;n2]
  if[n1=n2;:10];
  n1: string n1;
  n2: string n2;
  min_count:min(count n1;count n2);
  if[(`$ min_count # n1)=(`$ min_count # n2);:9];
  np1: " " vs n1;
  np2: " " vs n2;
  if[(`$np1[0])=`$np2[0];:5];
  score: count (`$ np1) inter `$ np2;
  score
  };

.agrar.calculate_name_score:{[n1;n2;nc1;nc2]
  .agrar.compare_names[n1;n2] * 2 / ((log nc1) + log nc2)
  };

.agrar.init:{[]
  .agrar.root: raze system "pwd";
  .agrar.input: .agrar.root,"/../input/csv/";
  .agrar.output: .agrar.root,"/../outout/";

  .agrar.raw: .agrar.load_csvs[];
  .agrar.compact: .agrar.create_compact[.agrar.raw];
  .agrar.network: .agrar.create_network[.agrar.compact];
  };

if[`CREATE_NETWORK=`$.z.x[0];
  .agrar.init[];
  // exit 0;
  ];
