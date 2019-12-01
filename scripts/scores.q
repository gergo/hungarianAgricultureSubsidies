system "l utils.q";

.agrar.given_names: raze .agrar.download_names each ("osszesffi";"osszesnoi");

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
  // if 2 names match -> 10 points
  if[n1=n2;:10];

  // if one is the prefix of the other (happens for married couples) -> 9 points
  n1: string n1;
  n2: string n2;
  min_count:min(count n1;count n2);
  if[(`$ min_count # n1)=(`$ min_count # n2);:9];

  // same family name -> 5 points
  np1: `$ " " vs n1;
  np2: `$ " " vs n2;
  if[(np1[0])=np2[0];:5];

  // remove given names -> count matching words (0 for no match)
  np1: (1 # np1),(1 _ np1) except .agrar.given_names;
  np2: (1 # np2),(1 _ np2) except .agrar.given_names;
  score: 2 * count np1 inter np2;
  score
  };

.agrar.calculate_name_score:{[n1;n2;nc1;nc2]
  .agrar.compare_names[n1;n2] * 2 / ((log nc1) + log nc2)
  };
