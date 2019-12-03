\c 25 180

system "l scores.q";

///
// Raw data is too large so we group subsidies together
.agrar.create_compact:{[raw]
  compact: select sum amount,wins: count i by name,zip,city,address from raw;
  compact: delete from compact where amount<1500000;
  compact: compact lj select name_count: count i by name from compact;
  .agrar.log "collapsed raw data created - ", string count compact;
  compact
  }

///
// create simple network by joining entries with the same zip code
// This is a good heuristic to reduce network size to a manageable size
.agrar.create_network_zip:{[compact]
  ppl1: update id: i from compact;
  ppl1: () xkey delete zip1 from update zip: zip1 from xcol[raze {`$raze string x,"1"} each cols ppl1; ppl1];

  ppl2: update id: i from compact;
  ppl2: () xkey delete zip2 from update zip: zip2 from xcol[raze {`$raze string x,"2"} each cols ppl2; ppl2];

  network: delete from ej[`zip;ppl1;ppl2] where id1>=id2;
  .agrar.log "created network skeleton - ", string count network;

  network: update address_score:.agrar.compare_addresses'[address1;address2] from network;
  .agrar.log "  address scores calculated";
  .agrar.add_score_to_nw[network]
  };

///
// On smaller datasets cross-join is doable
.agrar.create_network_full:{[compact]
  ppl1: update id: i from compact;
  ppl1: () xkey delete zip1 from update zip: zip1 from xcol[raze {`$raze string x,"1"} each cols ppl1; ppl1];

  ppl2: update id: i from compact;
  ppl2: () xkey delete zip2 from update zip: zip2 from xcol[raze {`$raze string x,"2"} each cols ppl2; ppl2];

  network: delete from (ppl1 cross ppl2) where id1>=id2;
  .agrar.log "created network skeleton - ", string count network;

  network: update address_score:.agrar.compare_addresses'[city_addr1;city_addr2] from network;
  .agrar.log "  address scores calculated";
  .agrar.add_score_to_nw[network]
  };

.agrar.add_score_to_nw:{[network]
  network: update name_score:.agrar.calculate_name_score'[name1;name2;name_count1;name_count2] from network;
  .agrar.log "  name scores calculated";
  network: update score: address_score+name_score from network;
  .agrar.log "strength (score) of relationship calculated";
  network
  }

.agrar.init:{[]
  .agrar.raw: .agrar.load_individuals[];
  .agrar.compact: .agrar.create_compact[.agrar.raw];
  .agrar.network: .agrar.create_network_zip[.agrar.compact];

  .agrar.log "saving csvs";
  .agrar.save_csv["compact";.agrar.compact];
  .agrar.save_csv["network";select id1,id2,score from .agrar.network];
  .agrar.save_csv["network_non_zero";update id1,id2,score from .agrar.network where score<>0];
  .agrar.zero_ones: update zero_one:{$[x<3;:0;:1]}'[score] from select id1,id2,score from .agrar.network where score<>0;
  .agrar.save_csv["network_zero_one";.agrar.zero_ones];
  };

if[`CREATE_NETWORK=`$.z.x[0];
  .agrar.init[];
  exit 0;
  ];
