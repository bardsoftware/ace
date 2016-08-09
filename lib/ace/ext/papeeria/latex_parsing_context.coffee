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
    getContext = (session, row) ->
        states = session.getState(row)
        if (Array.isArray(states))
            return states[states.length - 1]
        else
            return states

    getNestedListDepth = (session, row) ->
        states = session.getState(row)
        count = 0
        for state in states
            if state == LIST_STATE
                count++
        # because we have 2 LIST_STATE for 1 level of nested
        # and 3 LIST_STATE for more level
        return count - 1

    exports.getContext = getContext
    exports.getNestedListDepth = getNestedListDepth
    return
)
