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
			left: 0,
			width: '98%'
		});
		$("li a[href^='#']", this.container)
			.each(function() { new TitleBar.Menu(this); });
	}
};

var FarmFacts = function($) {
	$.lazy({ src: '/javascripts/jquery.jclock.js',
		name: 'jclock', cache: true });
	$.lazy({ src: '/javascripts/jquery-ui.js',
		name: 'draggable', cache: true });
	$.lazy({ src: '/javascripts/ui/ui.tabs.js',
		dependencies: { js: ['/javascripts/jquery-ui.js'] },
		name: 'tabs', cache: true });
	$.lazy({ src: '/javascripts/ui/ui.sortable.js',
		dependencies: { js: ['/javascripts/jquery-ui.js'] },
		name: 'sortable', cache: true });
	$.lazy({ src: '/javascripts/ui/ui.resizable.js',
		dependencies: { js: ['/javascripts/jquery-ui.js'] },
		name: 'resizable', cache: true });
	$.lazy({ src: '/javascripts/ui/ui.dialog.js',
		dependencies: { js: ['/javascripts/jquery-ui.js'] },
		name: 'dialog', cache: true });
	$.lazy({ src: '/javascripts/jquery.jeditable.js',
		name: 'editable', cache: true });

	$.fn.revealing = function() {
		return this
			.mouseover(function() { $('.hidden', this).show(); })
			.mouseout(function() { $('.hidden', this).hide(); });
	}
	$.fn.selected = function() { return this.focus().select(); }
	$.fn.loadsScript = function() {
		return this.click(function(e) {
			$.post(this.href, null, null, 'script');
			e.stopPropagation();
			e.preventDefault();
		});
	}

	$(function() {
		$('.hidden').hide();
		$('.revealing').revealing();
		$('.selected').selected();
		$('.loadsScript').loadsScript();

		TitleBar.initialize('#top'); // TODO: make this a jquery
		var query = $('.clock');
		if(query.length > 0) query.jclock();
		var query = $('#tabs');
		if (query.length > 0) { query.tabs(); }

		// add button behaviour to links
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

	FarmFacts.dialog = function(query, caption, options) {
		var buttons = {};
		buttons[caption] = function() { $(this).dialog('close'); };

		var options = $.extend({
			bgiframe: true,
			draggable: false,
			resizable: false,
			autoOpen: true,
			height: 'auto',
			buttons: buttons
		}, options);

		$(function() { $(query).dialog(options); });
	};
};
