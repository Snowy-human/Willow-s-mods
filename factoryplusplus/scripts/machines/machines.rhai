fn define(mod_info) {
	import "factoryplusplus/scripts/machines/bender.rhai" as bender;
	import "factoryplusplus/scripts/machines/hammer.rhai" as hammer;
	
	bender::define(mod_info);
	hammer::define(mod_info);
}
