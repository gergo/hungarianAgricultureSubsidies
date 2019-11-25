\c 25 180
\p 8848

.agrar.load_csvs:{[]
  .agrar.root: system "pwd";
  .agrar.input: .agrar.root,"/../input/csv/";
  .agrar.input: .agrar.root,"/../outout/";
  };

.agrar.init:{[]
  .agrar.load_csvs[];
  };

if[`CREATE_NETWORK=`$.z.x[0];
  .agrar.init[];
  exit 0;
  ];
