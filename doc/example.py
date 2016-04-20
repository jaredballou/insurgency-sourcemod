import keyvalues

kv = keyvalues.KeyValues()
kv.load_from_file("/home/insserver/insurgency-tools/public/data/mods/insurgency/2.1.6.0/scripts/theaters/default_checkpoint.theater")
#kv.kv["Databases"]["driver_default"] = "mysql"
kv.recurse_keyvalues()
kv.save_to_file("default_checkpoint.theater")
