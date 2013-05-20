(($, window) ->
	$(document).ready ->
		$("#main").stylish("scripts/stylish.php")
		
		$('#toggle_stylish').on 'click', (e) ->
			$("#main").stylish('toggle')
)(jQuery, window)