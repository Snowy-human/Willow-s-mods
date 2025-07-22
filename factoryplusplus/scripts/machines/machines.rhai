fn define(mod_info) {
	import "factoryplusplus/scripts/machines/bender.rhai" as bender;
	import "factoryplusplus/scripts/machines/hammer.rhai" as hammer;
	import "factoryplusplus/scripts/machines/miner.rhai" as miner;
	
	bender::define(mod_info);
	hammer::define(mod_info);
	miner::define(mod_info);
}
