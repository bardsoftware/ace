define( (require, exports, module) ->
  PapeeriaLatexHighlightRules = require('./papeeria_latex_highlight_rules')
  EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
  LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
  equationEnvironments = [
    'equation'
    'equation*'
  ]
  listEnvironments = [
    'itemize'
    'enumerate'
  ]

  basicSnippets = [
    {
      caption: "\\usepackage[]{..."
      snippet: """
            \\usepackage{${1  :package}}\n\
        """
      meta: "base"
    }
    {
      caption: "\\usepackage[]{..."
      snippet: """
            \\usepackage[${1:[options}]{${2:package}}\n\
        """
      meta: "base"
    }
    {
      caption: "\\newcommand{..."
      snippet: """
            \\newcommand{\\${1:cmd}}[${2:opt}]{${3:realcmd}}${4}\n\
        """
      meta: "base"
    }
  ]
  listSnippets = for env in listEnvironments
    {
      caption: "\\begin{#{env}}..."
      snippet: """
                \\begin{#{env}}
                \t\\item $1
                \\end{#{env}}
            """
      meta: "list"
    }
  equationSnippets = for env in equationEnvironments
    {
      caption: "\\begin{#{env}}..."
      snippet: """
                  \\begin{#{env}}
                  \t$1
                  \\end{#{env}}
              """
      meta: "equation"
    }
  formulasSnippets = [
    {
      caption: "\\frac{num}{denom}"
      snippet: """
                \\frac{${1:num}}{${2:denom}}
            """
      meta: "equation"
    }
    {
      caption: "\\sum{n}{i=..}{..}"
      snippet: """
                  \\sum^{${1:n}}_{${2:i=1}}{${3}}
            """
      meta: "equation"
    }
  ]

  equationKeywords = ['\\alpha']
  listKeywords = ['\\item']

  listKeywords_ = listKeywords.map((word) ->
    caption: word,
    value: word
    meta: 'list'
  )
  equationKeywords_ = equationKeywords.map((word) ->
    caption: word,
    value: word
    meta: 'equation'
  )

  exports.getCompletions = (editor, session, pos, prefix, callback) ->
    context = session.getContext(pos.row)
    if context == "start"
      callback(null, listSnippets.concat(equationSnippets.concat(basicSnippets)))

    if context == LIST_STATE
      callback(null, listKeywords_.concat(listSnippets.concat(equationSnippets)))

    if context == EQUATION_STATE
      callback(null, formulasSnippets.concat(equationKeywords_))
  return
) 