var FarmFacts = {

	initialize: function() {
		this.hide_hidden_elements();
		this.register_lazy_loaded();
		this.start_clock();
	},

	hide_hidden_elements: function() {
		$(function() { $('.hidden').hide(); });
	},

	register_lazy_loaded: function() {
		$.lazy({
			src: '/javascripts/jquery/jclock.js',
			name: 'jclock',
			cache: true
		});
		$.lazy({
			src: '/javascripts/jquery/ui/resizable.js',
			name: 'resizable',
			cache: true
		});
		$.lazy({
			src: '/javascripts/jquery/ui/draggable.js',
			name: 'draggable',
			cache: true
		});
		$.lazy({
			src: '/javascripts/jquery/ui/dialog.js',
			name: 'dialog',
			cache: true
		});
		$.lazy({
			src: '/javascripts/jquery/ui/fg/menu.js',
			name: 'menu',
			dependencies: {
				css: ['/javascripts/jquery/ui/fg/menu.css']
			},
			cache: true
		});

	},

	start_clock: function() {
		$(function() { $('.clock').jclock(); });
	},

	form: function(xpath, caption) {
		buttons = {};
		buttons[caption] = function() { $(this).dialog('close'); };

		$(xpath).dialog({
			bgiframe: true,
			closeOnEscape: false,
			draggable: false,
			resizable: false,
			autoOpen: true,
			height: 'auto',
			buttons: buttons,
			beforeclose: function() { $('form', this).submit(); }
		});
	}
};