foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  HashHandler = require("ace/keyboard/hash_handler")
  PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")
  EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
  LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
  equationEnvironments = [
    "equation"
    "equation*"
  ]
  listEnvironments = [
    "itemize"
    "enumerate"
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

  equationKeywords = ["\\alpha"]
  listKeywords = ["\\item"]

  listKeywords = listKeywords.map((word) ->
    caption: word,
    value: word
    meta: "list"
  )
  equationKeywords = equationKeywords.map((word) ->
    caption: word,
    value: word
    meta: "equation"
  )

  # Specific for token"s system of type in ace
  # We saw such a realization in html_completions.js
  isType = (token, type) ->
    return token.type.split(".").indexOf(type) > -1


  init = (editor, bindKey) ->
    keyboardHandler = new HashHandler.HashHandler()
    keyboardHandler.addCommand(
      name: "add item in list mode"
      bindKey: bindKey
      exec: (editor) ->
        cursor = editor.getCursorPosition();
        line = editor.session.getLine(cursor.row);
        tabString = editor.session.getTabString();
        indentString = line.match(/^\s*/)[0];
        indexOfBegin = line.indexOf("begin")

        if LatexParsingContext.getContext(editor.session, cursor.row) == LIST_STATE &&  indexOfBegin < cursor.column
          if indexOfBegin > -1
            editor.insert("\n" + tabString + indentString + "\\item ")
          else
            editor.insert("\n" + indentString + "\\item ")
          return true
        else
          return false
    )
    editor.keyBinding.addKeyboardHandler(keyboardHandler)

   class  ReferenceGetter
    constructor: ->
      @lastFetchedUrl =  ""
      @cache = []
    processData: (data) =>
      @cache = data.Labels?.map((elem) =>
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
      else
        callback(null, @cache)

  class TexCompleter
      constructor: ->
        @refGetter = new ReferenceGetter()
      @init: (editor) ->  init(editor,  {win: "enter", mac: "enter"})

      setReferencesUrl: (url) => @referencesUrl = url
      ###
      # callback -- this function is adding list of completions to our popup. Provide by ACE completions API
      # @param {object} error -- convention in node, the first argument to a callback
      # is usually used to indicate an error
      # @param {array} response -- list of completions for adding to popup
      ###
      getCompletions: (editor, session, pos, prefix, callback) =>
        context = LatexParsingContext.getContext(session, pos.row)
        token = session.getTokenAt(pos.row, pos.column)

        if isType(token, "ref") and @referencesUrl?
          @refGetter.getReferences(@referencesUrl, callback)
        else switch context
          when "start" then callback(null, listSnippets.concat(equationSnippets.concat(basicSnippets)))
          when LIST_STATE then callback(null, listKeywords.concat(listSnippets.concat(equationSnippets)))
          when EQUATION_STATE then callback(null, formulasSnippets.concat(equationKeywords))

  return TexCompleter
)
