\c 25 180
\p 8848

.agrar.load_csvs:{[]
  show "loading raw CSVs";
  .agrar.root: raze system "pwd";
  .agrar.input: .agrar.root,"/../input/csv/";
  .agrar.output: .agrar.root,"/../outout/";

  files: system "ls ",.agrar.input, "utf8_*csv";
  };

.agrar.process_file:{[f]
  yr: `$ ssr[ssr[f;csv_dir;""];".csv.utf8";""];
  show "  processing raw data for ", string yr;
  t: ("SISSSSSI";enlist";")0:`$f;
  t: `name`zip`city`address`reason`program`source`amount xcol t;
  t: update year: yr from t;
  t
};

.agrar.init:{[]
  .agrar.load_csvs[];
  };

if[`CREATE_NETWORK=`$.z.x[0];
  .agrar.init[];
  exit 0;
  ];
