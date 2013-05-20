(($, window) ->
	className =
		mode: 'stylish-mode'
		wrapper: 'stylish-wrapper'
		inputSelector: 'input-selector'
		inputStyle: 'input-style'
		inputStoredSelectors: 'stored-styles'

	templates =
		hoverWrapper:
			"""
				<div class="#{className.wrapper}"></div>
			"""
		dialog:
			"""
				<div class="stylish popover bottom">
					<div class="arrow"></div>

					<div class="popover-content">
						<small class="muted size"></small>
						<label>Stored:</label>
						<select class="#{className.inputStoredSelectors} input-large"></select>
						<label>Selector:</label>
						<input type="text" class="#{className.inputSelector} input-large pull-left" />
						<div class="btn-toolbar pull-left selector-level">
							<div class="btn-group">
								<a class="btn btn-mini select-up" href="#"><i class="icon-circle-arrow-up"></i></a>
								<a class="btn btn-mini select-down" href="#"><i class="icon-circle-arrow-down"></i></a>
							</div>
						</div>
						<textarea rows="5" class="#{className.inputStyle} input-xlarge"></textarea>
						<div class="text-center">
							<button class="btn btn-save">Save</button>
						</div>
					</div>
				</div>
			"""
		storeSelectorOption:
			"""
				<option value="0" class="muted">Not stored</option>
			"""

	class Stylish
		active: false
		editing: false
		settings: {}
		$container: undefined
		$element: undefined
		$wrapper: undefined
		$dialog: undefined

		constructor: (container, options) ->
			@init(container, options)

		# Initialize
		init: (container, options) ->
			# Assign post url for data
			if typeof options is 'string'
				options =
					post: options

			# Stablish the settings
			@settings = $.extend({}, @defaults, options)
			throw Error('You need to define the \'post\' parameter.') unless @settings.post

			# Initialize jQuery elements
			@$container = $(container)

			# Correct element
			if @$container.is(document) or @$container.is(window)
				@$container = $('body')

			@$wrapper = $(templates.hoverWrapper)
			@$dialog = $(templates.dialog)
			@$container
				.append(@$wrapper)
				.append(@$dialog)
			
			@$container.addClass(className.mode)
			@$container.on('mouseover', '*', @displayOver)
			@$container.on('click', '*', @displayEditor)
			@$dialog.on('click', '.selector-level .btn', @changeLevel)
			@$dialog.on('click', '.btn-save', @saveStyles)
			@$dialog.on('change', ".#{className.inputStoredSelectors}", @selectStyle)

			$.ajax
				url: @settings.post
				data: { json: 1 }
				type: 'GET'
				success: @setStyleData

		# Dom utilities
		getSelector: ($element) ->
			selector = $element[0].nodeName
			id = $element.attr('id')
			classNames = $element.attr('class')

			selector += "##{id}" if id
			selector += ".#{$.trim(classNames).replace(/\s/gi, '.')}" if classNames

			selector.toLowerCase()
		getCompleteSelector: ($element, level) =>
			parents = $element
							.parents()
							.map((index, element) => @getSelector($(element)) if index < level)
							.get()
							.reverse()
							.join(' > ')
			current = @getSelector($element)

			selector = if parents then "#{parents} > #{current}" else "#{current}"

			selector.replace(".#{className.mode}", '')
		addStyleToElement: (selector, style) ->
			$(selector).each (index, element) ->
				$this = $(element)
				data = $this.data('styles')
				if not data
					data = {}
				data[selector] = { style: style }
				$this.data('styles', data)
			
		closeDialog: =>
			@editing = false
			@$element = null
			@$dialog.hide()
		setInputValues: (selector) =>
			styles = @$element.data('styles')
			styleText = ""

			if styles and styles[selector]
				styleText = @json2Css(styles[selector].style)
			
			@$dialog.find(".#{className.inputSelector}").val(selector)
			@$dialog.find(".#{className.inputStyle}").val(styleText)
			@$dialog.find(".#{className.inputStoredSelectors}").val(selector)

		# Misc utilities
		css2Json: (cssText) ->
			obj = {}

			attributes = cssText.replace('\n', '').split(';')
			attributes.pop()	# Remove the last element, because it's empty
			for line in attributes
				index = line.indexOf(':')
				attribute = $.trim(line.substring(0, index))
				value = $.trim(line.substr(index + 1)).replace(';', '')

				obj[attribute] = value

			obj
		json2Css: (cssJson) ->
			style = ""
			for attribute, value of cssJson
				style += "#{attribute}: #{value};\n"

			style

		# Actions
		on: ->
			@active = true
			@$wrapper.show()
		off: ->
			@active = false
			@$wrapper.hide()
		toggle: ->
			if @active then @off() else @on()
		destroy: ->
			@$wrapper.remove()
			@$container.off('mouseover', '*', @displayOver)
			@$container.off('click', '*', @displayEditor)
			@$dialog.off('click', '.selector-level .btn', @changeLevel)
			@$dialog.off('click', '.btn-save', @saveStyles)
			@$dialog.off('change', ".#{className.inputStoredSelectors}", @selectStyle)
			@$container.data('stylish', null)

		# AJAX
		setStyleData: (styles) =>
			for selector, style of styles
				@addStyleToElement(selector, style)

			undefined

		# Events
		displayOver: (e) =>
			return if not @active or @editing

			$this = $(e.target)

			@$wrapper.width($this.outerWidth())
			@$wrapper.height($this.outerHeight())
			@$wrapper.offset($this.offset())

			@$wrapper.show()
		displayEditor: (e) =>
			e.preventDefault()
			e.stopPropagation()
			return unless @active

			$this = $(e.target)

			if @editing
				if $this.is('.stylish.popover') or $this.parents('.stylish.popover').size() > 0
					return
				else	# Close dialog when clicking outside the dialog
					@closeDialog()
					return

			@editing = true
			@$element = $this
			options = [ templates.storeSelectorOption ]
			selector = @getCompleteSelector($this, 0)

			if @$element.data('styles')
				styles = @$element.data('styles')

				for sel of styles
					options.push("<option value=\"#{sel}\">#{sel}</option>")
			
			storedStyles = options.join('')
			
			@$dialog.find('.size').html("#{$this.width()}px x #{$this.height()}px")
			@$dialog.find(".#{className.inputStoredSelectors}").html(storedStyles)
			@setInputValues(selector)
			@$dialog
				.show()
				.offset	# TODO: Improve calculation of the location for the popover
					top: $this.offset().top + $this.outerHeight() + 7	# Calculate position for top arrow
					left: $this.offset().left + 15
		changeLevel: (e) =>
			$this = $(e.currentTarget)
			level = @$element.data('level') or 0
			selector = ""

			if $this.is('.select-up')
				level++ if level < @$element.parents().size()
			else
				level-- if level > 0

			selector = @getCompleteSelector(@$element, level)

			@setInputValues(selector)
			@$element.data('level', level)
		saveStyles: (e) =>
			cssText = @$dialog.find(".#{className.inputStyle}").val().replace('\n', ' ')
			selector = @$dialog.find(".#{className.inputSelector}").val()
			value = @css2Json(cssText)

			$.ajax
				url: @settings.post
				data:
					selector: selector
					value: value
				type: 'POST'
				success: =>
					$(selector).css(value)
					@addStyleToElement(selector, value)
					@closeDialog()
				error: =>
					# TODO: Display error
		selectStyle: (e) =>
			$this = $(e.target)
			selector = $this.val()

			if selector is '0'
				selector = @getCompleteSelector(@$element, 0)

			@setInputValues(selector)


	# Define plugin
	$.fn.stylish = (options) ->
		@each ->
			data = $(this).data('stylish') 
			if data is undefined
				plugin = new Stylish(this, options)
				$(this).data('stylish', plugin)
			else
				if typeof options is 'string'
					data[options]()

	Stylish::defaults =
		post: undefined

	undefined
)(jQuery, window)