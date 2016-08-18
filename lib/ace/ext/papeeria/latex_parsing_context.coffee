foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
    PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")
    EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
    LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
    ###
     * @param {Number} row
     *
     * Returns context at row.
    ###
    # Specific for token"s system of type in ace
  # We saw such a realization in html_completions.js
    isType = (token, type) ->
        return token.type.split(".").indexOf(type) > -1

    getContext = (session, row, column) ->
        token = session.getTokenAt(row, column)
        if token? and isType(token, "math")
            return EQUATION_STATE
        else
            getContextFromRaw(session, row)

    getContextFromRaw = (session, row) ->
        states = session.getState(row)
        if (Array.isArray(states))
            return states[states.length - 1]
        else
            return states

    exports.getContext = getContext
    exports.isType = isType
    return
)
