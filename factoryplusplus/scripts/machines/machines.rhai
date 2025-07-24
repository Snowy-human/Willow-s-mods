fn define(mod_info) {
	import "factoryplusplus/scripts/machines/bender.rhai" as bender;
	import "factoryplusplus/scripts/machines/hammer.rhai" as hammer;
	import "factoryplusplus/scripts/machines/miner.rhai" as miner;
	import "factoryplusplus/scripts/machines/condensation.rhai" as condensation;
	
	bender::define(mod_info);
	hammer::define(mod_info);
	miner::define(mod_info);
	condensation::define(mod_info);
}
