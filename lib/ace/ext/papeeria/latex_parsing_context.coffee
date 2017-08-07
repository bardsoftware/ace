foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
    PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")

    LPAREN_TOKENTYPE = PapeeriaLatexHighlightRules.LPAREN_TOKENTYPE
    RPAREN_TOKENTYPE = PapeeriaLatexHighlightRules.RPAREN_TOKENTYPE
    EQUATION_TOKENTYPE = PapeeriaLatexHighlightRules.EQUATION_TOKENTYPE
    LIST_TOKENTYPE = PapeeriaLatexHighlightRules.LIST_TOKENTYPE
    ENVIRONMENT_TOKENTYPE = PapeeriaLatexHighlightRules.ENVIRONMENT_TOKENTYPE
    FIGURE_TOKENTYPE = PapeeriaLatexHighlightRules.FIGURE_TOKENTYPE
    TABLE_TOKENTYPE = PapeeriaLatexHighlightRules.TABLE_TOKENTYPE

    TOKENTYPES = [EQUATION_TOKENTYPE, LIST_TOKENTYPE, FIGURE_TOKENTYPE, ENVIRONMENT_TOKENTYPE, TABLE_TOKENTYPE]

    # Specific for token"s system of type in ace
    isType = (token, type) ->
        return token.type.split(".").indexOf(type) > -1

    ###
     * @param {(number, number) pos}
     *
     * Returns context at cursor position.
    ###
    getContext = (session, row, column) ->
        state = getContextFromRow(session, row)
        token = session.getTokenAt(row, column)
        if token?
            for i in [0..TOKENTYPES.length-1]
                if isType(token, TOKENTYPES[i])
                    return TOKENTYPES[i]
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
