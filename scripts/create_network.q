\c 25 180
\p 8848

system "l utils.q";
system "l scores.q";

///
// Raw data is too large so we group subsidies together
.agrar.create_compact:{[raw]
  compact: select sum amount,wins: count i by name,zip,city,address from raw;
  compact: compact lj select name_count: count i by name from compact;
  show "collapsed raw data created - ", string count compact;
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

  network: update address_score:.agrar.compare_addresses'[address1;address2] from network;
  network: update name_score:.agrar.calculate_name_score'[name1;name2;name_count1;name_count2] from network;
  network: update score: address_score+name_score from network;
  show "strength (score) of relationship calculated";
  network
  };

.agrar.init:{[]
  .agrar.raw: .agrar.load_csvs[];
  .agrar.compact: .agrar.create_compact[.agrar.raw];
  .agrar.network: .agrar.create_network[.agrar.compact];

  show "saving csvs";
  .agrar.save_csv["compact";.agrar.compact];
  .agrar.save_csv["network";select id1,id2,score from .agrar.network];
  .agrar.save_csv["network_non_zero.csv";select id1,id2,score from .agrar.network where score<>0];
  };

if[`CREATE_NETWORK=`$.z.x[0];
  .agrar.init[];
  exit 0;
  ];
