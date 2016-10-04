foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
    PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")

    EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
    LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
    ENVIRONMENT_STATE = PapeeriaLatexHighlightRules.ENVIRONMENT_STATE
    TABLE_STATE = PapeeriaLatexHighlightRules.TABLE_STATE
    FIGURE_STATE = PapeeriaLatexHighlightRules.FIGURE_STATE


    EQUATION_TOKENTYPE = PapeeriaLatexHighlightRules.EQUATION_TOKENTYPE
    LIST_TOKENTYPE = PapeeriaLatexHighlightRules.LIST_TOKENTYPE
    ENVIRONMENT_TOKENTYPE = PapeeriaLatexHighlightRules.ENVIRONMENT_TOKENTYPE
    FIGURE_TOKENTYPE = PapeeriaLatexHighlightRules.FIGURE_TOKENTYPE
    TABLE_TOKENTYPE = PapeeriaLatexHighlightRules.TABLE_TOKENTYPE

    TOKEN_TYPES = [EQUATION_TOKENTYPE, LIST_TOKENTYPE, FIGURE_TOKENTYPE, ENVIRONMENT_TOKENTYPE, TABLE_TOKENTYPE]
    STATES =  [EQUATION_STATE, LIST_STATE, FIGURE_STATE, ENVIRONMENT_STATE, TABLE_STATE]

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
            for i in [0..TOKEN_TYPES.length-1]
                if isType(token, TOKEN_TYPES[i])
                    return STATES[i]
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
