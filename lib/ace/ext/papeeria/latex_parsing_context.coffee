foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
    PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")
    EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
    LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE

    EQUATION_TOKENTYPE  = PapeeriaLatexHighlightRules.EQUATION_TOKENTYPE
    LIST_TOKENTYPE  = PapeeriaLatexHighlightRules.LIST_TOKENTYPE


    # Specific for token"s system of type in ace
    isType = (token, type) ->
        return token.type.split(".").indexOf(type) > -1
    ###
     * @param {Number} row
     * @param {Number} column
     *
     * Returns context at position.
    ###
    getContext = (session, row, column) ->
        state = getContextFromRow(session, row)
        token = session.getTokenAt(row, column)
        if token?
            if isType(token, EQUATION_TOKENTYPE)
                return EQUATION_STATE
            if isType(token, LIST_TOKENTYPE)
                return LIST_STATE
        return state


    getContextFromRow = (session, row) ->
        states = session.getState(row)
        if (Array.isArray(states))
            return states[states.length - 1]
        else
            return states

    exports.getContext = getContext
    exports.isType = isType
    return
)