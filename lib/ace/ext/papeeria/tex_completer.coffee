define( (require, exports, module) ->
  PapeeriaLatexHighlightRules = require('./papeeria_latex_highlight_rules')
  ContextHelper = require('./context_helper')
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
      caption: "\\ref{..."
      snippet: """
            \\ref{${1}}
        """
      meta: "base"
    }
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
  equationKeywords = equationKeywords.map((word) ->
    caption: word,
    value: word
    meta: 'equation'
  )
  
  # Specific for token's system of type in ace
  # We saw such a realization in html_completions.js
  istype = (token, type) -> 
    return token.type.lastIndexOf(type) > -1
  

  init = (editor, bindKey) -> 
    HashHandler = require("ace/keyboard/hash_handler").HashHandler
    keyboardHandler = new HashHandler()
    keyboardHandler.addCommand(
      name: 'add item in list mode'
      bindKey: bindKey
      exec: (editor) ->  
        pos = editor.getCursorPosition()
        curLine = editor.session.getLine(pos.row)
        indentCount = ContextHelper.getNestedListDepth(editor.session, pos.row)
        tabString = editor.getSession().getTabString()
        # it's temporary fix bug with added \item before \begin{itemize|enumerate}
        if ContextHelper.getContext(editor.session, pos.row) == LIST_STATE && curLine.indexOf("begin") < pos.column
          editor.insert("\n" + tabString.repeat(indentCount) + "\\item ")
          return true
        else 
          return false
    )
    editor.keyBinding.addKeyboardHandler(keyboardHandler)

   class ReferenceGetter
    constructor: ->
      @lastFetchedUrl =  ""
      @cache = []
    processData: (data) => 
      @cache = data.map((elem) => 
          return {
            name: elem.caption
            value: elem.caption
            meta: elem.type + "-ref" 
          }
    )
    getReferences: (url, callback) => 
      if url != @lastFetchedUrl
        $.getJSON(url).done((data) => 
          @processData(data)
          callback(null, @cache)
          @lastFetchedUrl = url
        )

  class TexCompleter
      constructor: ->
        @refGetter = new ReferenceGetter()
      #callback -- add items in popup
      getCompletions: (editor, session, pos, prefix, callback) =>
        context = ContextHelper.getContext(session, pos.row)
        token = session.getTokenAt(pos.row, pos.column)

        if istype(token, "ref")
          @refGetter.getReferences("example.json", callback)
        else if context == "start"
          callback(null, listSnippets.concat(equationSnippets.concat(basicSnippets)))
        else if context == LIST_STATE
          callback(null, listKeywords_.concat(listSnippets.concat(equationSnippets)))
        else if context == EQUATION_STATE
          callback(null, formulasSnippets.concat(equationKeywords))

  exports.CompletionTools = 
    TexCompleter: TexCompleter
    init: init
) 
