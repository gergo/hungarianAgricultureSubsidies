\c 25 180
\p 8848

.agrar.load_csvs:{[]
  .agrar.csv_dir: (system "pwd"),"/../csv/";
  };

.agrar.init:{[]
  .agrar.load_csvs[];
  };

if[`CREATE_NETWORK=`$.z.x[0];
  .agrar.init[];
  exit 0;
  ];
