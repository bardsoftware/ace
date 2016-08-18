foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  HashHandler = require("ace/keyboard/hash_handler")
  PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")


  EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
  LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
  EQUATION_SNIPPETS = require("./snippets/EquationSnippets")

  LIST_ENVIRONMENTS = [
    "itemize"
    "enumerate"
  ]

  EQUATION_ENVIRONMENTS = [
      "equation"
      "equation*"
  ]

  EQUATION_ENV_SNIPPETS = for env in EQUATION_ENVIRONMENTS
    {
      caption: "\\begin{#{env}}..."
      snippet: """
                \\begin{#{env}}
                \t$1
                \\end{#{env}}
            """
      meta: "equation"
    }


  REFERENCE_SNIPPET =
  {
      caption: "\\ref{..."
      snippet: """
            \\ref{${1}}
        """
      meta: "reference"
  }

  BASIC_SNIPPETS = [
    {
      caption: "\\usepackage[]{..."
      snippet: """
            \\usepackage{${1  :package}}\n\
        """
      meta: "base"
    }
    {
      caption: "\\usepackage[options]{..."
      snippet: """
            \\usepackage[${1:[options}]{${2:package}}\n\
        """
      meta: "base"
    }
    {
      caption: "\\newcommand{..."
      snippet: """
            \\newcommand{${1:cmd}}[${2:opt}]{${3:realcmd}}${0}\n\
        """
      meta: "base"
    }
  ]

  LIST_SNIPPET = for env in LIST_ENVIRONMENTS
    {
      caption: "\\begin{#{env}}..."
      snippet: """
                \\begin{#{env}}
                \t\\item $1
                \\end{#{env}}
            """
      meta: "list"
    }


  LIST_KEYWORDS = ["\\item"]
  LIST_KEYWORDS = LIST_KEYWORDS.map((word) ->
    caption: word,
    value: word
    meta: "list"
  )

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

  compare = (a, b) ->
    console.log(a.meta, b.meta)
    a.meta < b.meta
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
        token = session.getTokenAt(pos.row, pos.column)
        context = LatexParsingContext.getContext(session, pos.row, pos.column)

        if LatexParsingContext.isType(token, "ref") and @referencesUrl?
          @refGetter.getReferences(@referencesUrl, callback)
        else switch context
          when "start" then callback(null, BASIC_SNIPPETS.concat(LIST_SNIPPET,
            EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET))
          when LIST_STATE then callback(null, LIST_KEYWORDS.concat(EQUATION_ENV_SNIPPETS, LIST_SNIPPET))
          when EQUATION_STATE then callback(null, EQUATION_SNIPPETS)

  return TexCompleter
)
