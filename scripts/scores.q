system "l utils.q";

.agrar.given_names: raze .agrar.download_names each ("osszesffi";"osszesnoi");
.agrar.remove_names: `$("Dr.";"dr.";"Dr";"dr";"néhai";"Néhai");

.agrar.compare_addresses:{[a1;a2]
  // if addresses match -> 10 points
  if[a1=a2;:10.0];

  // if in same street -> 1 point
  a1: " " vs string a1;
  a2: " " vs string a2;
  if[1<count a1; a1: -1 _  a1];
  if[1<count a2; a2: -1 _  a2];
  if[(`$ raze a1)=`$ raze a2;:1.0];
  :0.0;
  };

.agrar.compare_names:{[n1;n2;final_score_fn]
  // if 2 names match -> 10 points
  if[n1=n2;:10.0];

  // if one is the prefix of the other (happens for married couples) -> 9 points
  n1: string n1;
  n2: string n2;
  min_count:min(count n1;count n2);
  if[(`$ min_count # n1)=(`$ min_count # n2);:9.0];

  // same family name -> 5 points
  // can cause false positives
  np1: (`$ " " vs n1) except .agrar.remove_names;
  np2: (`$ " " vs n2) except .agrar.remove_names;
  if[(np1[0])=np2[0];:5.0];

  // otherwise use the Levenshtein distance.
  // first remove given names
  np1: (1 # np1),(1 _ np1) except .agrar.given_names;
  np2: (1 # np2),(1 _ np2) except .agrar.given_names;
  final_score_fn[np1;np2]
  };

// Levenshtein distance to calculate distance between words
.agrar.lev_dist:{[w1;w2]
  $[w1~w2;0;
    count[w2]~0;count w1;
    count[w1]~0;count w2;
    [ min (.z.s[-1_w1;w2]+1;
      .z.s[w1;-1_w2]+1 ;
      .z.s[-1_w1;-1_w2] + not reverse[w1][0]~reverse[w2][0])]
    ]
  };

///
// modified distance calculation to make it suitable for comparing names
// .agrar.normalizedLevDist["asdf";"qwer"] -> 0f
// .agrar.normalizedLevDist["asdf";"asdf"] -> 1f
// .agrar.normalizedLevDist["foobar";"foofao"] -> 0.666667
.agrar.normalized_lev_dist:{[w1;w2]
  score: .agrar.lev_dist[w1;w2];
  length: max (count w1; count w2);
  (length - score) % length
  };

// cross-joins strings on word parts then splits the name parts by 6 characters as lev distance calculation is O(n^2)
.agrar.levenshtein_compare:{[n1;n2]
  words: ([] w1: (flip upper n1 cross n2)[0];w2: (flip upper n1 cross n2)[1]);
  words: ungroup update w1: {`$ 0N 5 # string x}'[w1] from words;
  words: ungroup update w2: {`$ 0N 5 # string x}'[w2] from words;
  words: update score:.agrar.normalized_lev_dist'[w1;w2] from string words;
  10.0 * avg exec score from words
  };

.agrar.calculate_name_score:{[n1;n2;nc1;nc2;final_score_fn]
  (.agrar.compare_names[n1;n2;final_score_fn] * 2.0) % 1 + (log nc1) + log nc2
  };
