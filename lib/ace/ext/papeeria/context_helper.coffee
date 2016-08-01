define( (require, exports, module) ->
    PapeeriaLatexHighlightRules = require('./papeeria_latex_highlight_rules')
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

    getNestingOfList = (session, row) -> 
        states = session.getState(row)
        count = 0
        arrayLength = states.length
        i = arrayLength - 1
        while i >= 0 and states[i] == LIST_STATE
            i--
            count++
        return count


    exports.ContextHelper = 
        getContext: getContext
        getNestingOfList: getNestingOfList
)
      