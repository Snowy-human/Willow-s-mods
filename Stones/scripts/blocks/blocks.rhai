fn define(mod_info) {
	import "Stones/scripts/blocks/salt.rhai" as salt;
	import "Stones/scripts/blocks/banded.rhai" as banded;
	
	salt::define(mod_info);
	banded::define(mod_info);
}
