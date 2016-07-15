define((require, exports, module) ->
	Range = require("ace/range").Range;

	exports.highlightingBrackets = (editor, pos) ->
		session = editor.getSession()
		if session.$bracketHighlightRight || session.$bracketHighlightLeft
			session.removeMarker(session.$bracketHighlightLeft)
			session.removeMarker(session.$bracketHighlightRight)
			session.$bracketHighlightLeft = null
			session.$bracketHighlightRight = null
		if !pos.mismatch
			rangeLeft = new Range(pos.left.row, pos.left.column, pos.left.row, pos.left.column + 1)
			rangeRight = new Range(pos.right.row, pos.right.column, pos.right.row, pos.right.column + 1)
			session.$bracketHighlightLeft = session.addMarker(rangeLeft, "ace_bracket", "text")
			session.$bracketHighlightRight = session.addMarker(rangeRight, "ace_bracket", "text")
		else
			if pos.left && pos.right 
			    range = new Range(pos.left.row, pos.left.column, pos.right.row, pos.right.column + 1)
			    session.$bracketHighlightLeft = session.addMarker(range, "ace_error-marker", "text")

			if pos.left && !pos.right
			    rangeLeft = new Range(pos.left.row, pos.left.column, Infinity, Infinity)
			    session.$bracketHighlightLeft = session.addMarker(rangeLeft, "ace_error-marker", "text")

			if pos.right && !pos.left
			    rangeRight = new Range(0, 0, pos.right.row, pos.right.column + 1)
    			session.$bracketHighlightRight = session.addMarker(rangeRight, "ace_error-marker", "text")
)