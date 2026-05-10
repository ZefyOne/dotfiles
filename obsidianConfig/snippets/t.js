exports.invoke = async (app) => {
	const switcherPlugin = app.internalPlugins.getPluginById('switcher');

	if (!switcherPlugin?.instance) {
		console.error("Quick switcher plugin not found.");
	} else {
		const ModalClass = switcherPlugin.instance.QuickSwitcherModal;
		const originalOnOpen = ModalClass.prototype.onOpen;

		ModalClass.prototype.onOpen = function() {
			originalOnOpen.apply(this, arguments);

			const downEntry = this.scope.keys.find(k => k.key === 'ArrowDown' && k.modifiers === '');
			const upEntry = this.scope.keys.find(k => k.key === 'ArrowUp' && k.modifiers === '');

			if (downEntry && upEntry) {
				this.scope.register(['Ctrl'], 'J', (e) => downEntry.func.call(this, e));
				this.scope.register(['Ctrl'], 'K', (e) => upEntry.func.call(this, e));
			}
		};	
	}
}
