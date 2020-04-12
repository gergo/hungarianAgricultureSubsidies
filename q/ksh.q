.ksh.process_settlements_file:{[]
  settlements: ("SISSSSSSSFFF";enlist",")0:`$"../input/settlements/helysegek.csv";
  .ksh.settlements: `helyseg`ksh_kod`tipus`megye`jaras_kod`jaras_nev`megyeszekhely`onkormanyzat_kod`onkormanyzat_szekhely`terulet`nepesseg`lakasok xcol settlements;
  };

.ksh.process_settlements_parts_file:{[]
  settlement_parts: ("ISFSIFSIFFF";enlist",")0:`$"../input/settlements/Telepulesreszek_2019_01_01.csv";
  settlement_parts: `ksh_kod`helyseg`megye_kod`telepulesresz`telepulesresz_jelleg_kod`iranyito_szam`kulterulet_jellege`tavolsag`nepesseg`lakasok`egyeb_lakoegysegek xcol settlement_parts;
  .ksh.settlement_parts: select sum nepesseg, sum lakasok by iranyito_szam,helyseg,ksh_kod from settlement_parts;
  };
