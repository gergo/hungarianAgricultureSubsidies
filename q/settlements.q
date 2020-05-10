.ksh.process_settlements_file:{[]
  settlements: ("SISSSSSSSFFF";enlist",")0:`$"../input/settlements/helysegek.csv";
  `helyseg`ksh_kod`tipus`megye`jaras_kod`jaras_nev`jaras_szekhely`onkormanyzat_kod`onkormanyzat_szekhely`terulet`nepesseg`lakasok xcol settlements
  };

.ksh.process_settlements_parts_file:{[]
  settlement_parts: ("ISFSIFSIFFF";enlist",")0:`$"../input/settlements/Telepulesreszek_2019_01_01.csv";
  settlement_parts: `ksh_kod`helyseg`megye_kod`telepulesresz`telepulesresz_jelleg_kod`iranyito_szam`kulterulet_jellege`tavolsag`nepesseg`lakasok`egyeb_lakoegysegek xcol settlement_parts;
  parts: update iranyito_szam: "i"$iranyito_szam from settlement_parts;
  parts1: select sum nepesseg, sum lakasok by iranyito_szam, helyseg, ksh_kod from parts;
  // raw data has a many-to-many relationship between zip_code and ksh_id
  select from parts1 where nepesseg = (max;nepesseg) fby ([]iranyito_szam;ksh_kod)
  };

.ksh.ksh_id_zip_map:{[]
  raw_settlement_parts: .ksh.process_settlements_parts_file[];
  settlement_parts: select distinct zip: iranyito_szam, ksh_id: ksh_kod, settlement: helyseg from raw_settlement_parts where iranyito_szam<>0N;
  postal_map: .posta.zip_map[];
  postal_map_with_ksh_id: postal_map lj 1! select distinct settlement,ksh_id from settlement_parts;
  joined: `zip xasc `zip xkey settlement_parts,select zip,ksh_id,settlement from postal_map_with_ksh_id;
  delete from joined where settlement like "Budapest*"
  };

.posta.zip_map:{[]
  raw: ("ISS";enlist",")0:`$"../input/zip_map/zip_map.csv";
  manual: ("ISS";enlist",")0:`$"../input/zip_map/manual_zip_map.csv";
  raw1: manual,`zip`settlement`settlement_part xcol raw;
  delete from raw1 where settlement_part=`
  };

.ksh.county_capitals:{[]
  ("SS";enlist",")0:`$"../input/settlements/megyeszekhelyek.csv"
  };
