.election.load_clean_file:{[]
  results: ("IISSSSSSBSSIIBISSSFSIISIFFF";enlist",")0:`$"../input/election/election_clean.csv";
  results: delete from results where year<2010;
  results: delete from results where not win;
  results
  };

.election.load_parsed_file:{[]
  results: ("IISSSSSSBSSIIBISSSFSIISIFFF";enlist",")0:`$"../input/election/election_parsed.csv";
  results: delete from results where year<2010;
  // results: delete from results where not win;
  results
  };
