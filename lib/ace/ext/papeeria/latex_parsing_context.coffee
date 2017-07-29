foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
    PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")

    {
        LPAREN_TOKENTYPE
        RPAREN_TOKENTYPE
        EQUATION_TOKENTYPE
        LIST_TOKENTYPE
        ENVIRONMENT_TOKENTYPE
        FIGURE_TOKENTYPE
        TABLE_TOKENTYPE

        SPECIFIC_TOKEN_FOR_STATE
    } = PapeeriaLatexHighlightRules

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
