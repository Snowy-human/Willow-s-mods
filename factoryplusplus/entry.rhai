fn setup(mod_info) {
	import "factoryplusplus/scripts/machines/machines.rhai" as machines;
	import "factoryplusplus/scripts/icons.rhai" as mppicons;
	
	machines::define(mod_info);
	mppicons::define(mod_info);
}

