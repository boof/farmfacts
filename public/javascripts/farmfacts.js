var TitleBar = {

	menus: [],
	close: function() {
		TitleBar.hideMenus();
		TitleBar.deactivate();
	},
	registerMenu: function(menu) {
		TitleBar.menus.push(menu);
	},
	activate: function(current) {
		$(TitleBar.menus).each(function() { this.activate(); });
		$(document).click(this.close);
	},
	hideMenus: function() {
		$(TitleBar.menus).each(function() { this.hide(); });
	},
	deactivate: function() {
		$(document).unbind('click', this.close);
		$(TitleBar.menus).each(function() { this.deactivate(); });
	},
	container: null,

	Menu: function(anchor) {
		this.label = $(anchor);
		this.label.parent('li').addClass('ui-menu-header');
		this.label.click(function(e) {
			TitleBar.hideMenus();
			TitleBar.activate();
			this.menu.show();
			e.stopPropagation();
		});

		var position = this.label.position();
		position.top += this.label.height();
		this.container = $(anchor.hash);
		this.container
			.click(function(e) { e.stopPropagation(); })
			.addClass('ui-menu-content ui-corner-bottom ui-widget-content')
			.css({ left: position.left, top: position.top });

		this.show = function() {
			this.label.addClass('active');
			this.container.show();
		};
		this.hide = function() {
			this.label.removeClass('active');
			this.container.hide();
		};
		this.activate = function() {
			this.label.mouseover(function() {
				TitleBar.hideMenus();
				this.menu.show();
			});
		};
		this.deactivate = function() {
			this.label.unbind('mouseover');
		};

		TitleBar.registerMenu(this);
		anchor.menu = this;
	},
	initialize: function(query) {
		this.container = $(query).css({
			position: 'fixed',
			top: 0,
			width: '98%'
		});
		$("li a[href^='#']", this.container)
			.each(function() { new TitleBar.Menu(this); });
	}
};

var FarmFacts = {

	initialize: function() {
		this.hide_hidden_elements();
		this.register_lazy_loaded();
		this.initialize_titlebar();
		this.start_clock();
		this.enhance_buttons();
		this.initialize_tabs();
	},

	initialize_titlebar: function() {
		$(function() { TitleBar.initialize('#top'); });
	},

	start_clock: function() {
		$(function() { $('.clock').jclock(); });
	},

	hide_hidden_elements: function() {
		$(function() { $('.hidden').hide(); });
	},

	register_lazy_loaded: function() {
		$.lazy({
			src: '/javascripts/jquery/ui/tabs.js',
			name: 'tabs',
			cache: true
		});
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

	initialize_tabs: function() {
		$(function() {
			query = $('#tabs');
			if (query.length > 0) { query.tabs(); }
		});
	},
	enhance_buttons: function() {
		$(function() {
			var q1 = $('a.submit')
				.click(function(e) { $(this).next('input').click(); e.preventDefault(); })
				.after('<input type="submit" style="display: none;" />');

			q1.add($('a.button')).add($('a.action'))
				.addClass('ui-state-default')
				.hover(
					function() { $(this).addClass('ui-state-hover'); },
					function() { $(this).removeClass('ui-state-hover'); }
				);
		});
	},

	form: function(query, caption) {
		buttons = {};
		buttons[caption] = function() { $(this).dialog('close'); };

		$(query).dialog({
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