// Generated by CoffeeScript 1.10.0
(function() {
  var foo,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  foo = null;

  define(function(require, exports, module) {
    var BASIC_SNIPPETS, CITATION_SNIPPET, CompletionsCache, ENVIRONMENT_LABELS, ENVIRONMENT_STATE, EQUATION_ENVIRONMENTS, EQUATION_ENV_SNIPPETS, EQUATION_SNIPPETS, EQUATION_STATE, FIGURE_STATE, HashHandler, LIST_END_ENVIRONMENT, LIST_ENVIRONMENTS, LIST_KEYWORDS, LIST_SNIPPET, LIST_STATE, LatexParsingContext, OTHER_ENVIRONMENTS, PapeeriaLatexHighlightRules, REFERENCE_SNIPPET, TABLE_STATE, TexCompleter, compare, env, processCitationJson, processReferenceJson, showPopupIfTokenIsOneOfTypes;
    HashHandler = require("ace/keyboard/hash_handler");
    PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules");
    LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context");
    EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE;
    LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE;
    ENVIRONMENT_STATE = PapeeriaLatexHighlightRules.ENVIRONMENT_STATE;
    TABLE_STATE = PapeeriaLatexHighlightRules.TABLE_STATE;
    FIGURE_STATE = PapeeriaLatexHighlightRules.FIGURE_STATE;
    EQUATION_SNIPPETS = require("ace/ext/papeeria/snippets/equation_snippets");
    LIST_ENVIRONMENTS = ["itemize", "enumerate", "description"];
    EQUATION_ENVIRONMENTS = ["equation", "equation*"];
    OTHER_ENVIRONMENTS = ["table", "figure"];
    ENVIRONMENT_LABELS = (function() {
      var i, len, ref, results;
      ref = EQUATION_ENVIRONMENTS.concat(OTHER_ENVIRONMENTS, LIST_ENVIRONMENTS);
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        env = ref[i];
        results.push({
          caption: env,
          value: env,
          meta: "environments",
          meta_score: 10
        });
      }
      return results;
    })();
    EQUATION_ENV_SNIPPETS = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = EQUATION_ENVIRONMENTS.length; i < len; i++) {
        env = EQUATION_ENVIRONMENTS[i];
        results.push({
          caption: "\\begin{" + env + "}...",
          snippet: "\\begin{" + env + "}\n\t$1\n\\end{" + env + "}",
          meta: "equation",
          meta_score: 10
        });
      }
      return results;
    })();
    LIST_END_ENVIRONMENT = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = LIST_ENVIRONMENTS.length; i < len; i++) {
        env = LIST_ENVIRONMENTS[i];
        results.push({
          caption: "\\end{" + env + "}",
          value: "\\end{" + env + "}",
          score: 0,
          meta: "End",
          meta_score: 1
        });
      }
      return results;
    })();
    REFERENCE_SNIPPET = {
      caption: "\\ref{...",
      snippet: "\\ref{${1}}",
      meta: "reference and citation",
      meta_score: 10
    };
    CITATION_SNIPPET = {
      caption: "\\cite{...",
      snippet: "\\cite{${1}}",
      meta: "reference and citation",
      meta_score: 10
    };
    compare = function(a, b) {
      return a.caption.localeCompare(b.caption);
    };
    BASIC_SNIPPETS = [
      {
        caption: "\\begin{env}...\\end{env}",
        snippet: "\\begin{$1}\n\t $2\n\\end{$1}",
        meta: "Any environment",
        meta_score: 100
      }, {
        caption: "\\begin{...}",
        snippet: "\\begin{$1}",
        meta: "Any environment",
        meta_score: 8
      }, {
        caption: "\\end{...}",
        snippet: "\\end{$1}",
        meta: "Any environment",
        meta_score: 8
      }, {
        caption: "\\usepackage[]{...",
        snippet: "\\usepackage{${1:package}}\n",
        meta: "base",
        meta_score: 9
      }, {
        caption: "\\section{...",
        snippet: "\\section{${1:name}}\n",
        meta: "base",
        meta_score: 9
      }, {
        caption: "\\subsection{...",
        snippet: "\\subsection{${1:name}}\n",
        meta: "base",
        meta_score: 9
      }, {
        caption: "\\subsubsection{...",
        snippet: "\\subsubsection{${1:name}}\n",
        meta: "base",
        meta_score: 9
      }, {
        caption: "\\chapter{...",
        snippet: "\\chapter{${1:name}}\n",
        meta: "base",
        meta_score: 9
      }, {
        caption: "\\begin{table}...",
        snippet: "\\begin{table}\n\t\\begin{tabular}{${1:tablespec}}\n\t\t $2\n\t\\end{tabular}\n\\end{table}",
        meta: "table",
        meta_score: 9
      }, {
        caption: "\\begin{figure}...",
        snippet: "\\begin{figure}[${1:placement}]\n\t $2\n\\end{figure}",
        meta: "figure",
        meta_score: 9
      }
    ];
    BASIC_SNIPPETS = BASIC_SNIPPETS.sort(compare);
    LIST_SNIPPET = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = LIST_ENVIRONMENTS.length; i < len; i++) {
        env = LIST_ENVIRONMENTS[i];
        results.push({
          caption: "\\begin{" + env + "}...",
          snippet: "\\begin{" + env + "}\n\t\\item $1\n\\end{" + env + "}",
          meta: "list",
          meta_score: 10
        });
      }
      return results;
    })();
    LIST_KEYWORDS = ["\\item"];
    LIST_KEYWORDS = LIST_KEYWORDS.map(function(word) {
      return {
        caption: word,
        value: word,
        meta: "list",
        meta_score: 10
      };
    });
    processReferenceJson = (function(_this) {
      return function(json) {
        var ref;
        return (ref = json.Labels) != null ? ref.map(function(elem) {
          return {
            name: elem.caption,
            value: elem.caption,
            score: 1000,
            meta: elem.type,
            meta_score: 10
          };
        }) : void 0;
      };
    })(this);
    processCitationJson = (function(_this) {
      return function(json) {
        var bibentries, bibfile, result;
        result = [];
        for (bibfile in json) {
          bibentries = json[bibfile];
          if (bibfile !== "" && bibentries !== "") {
            bibentries.map(function(entry) {
              return result.push({
                name: entry.id,
                value: entry.id,
                score: 1000,
                meta: bibfile,
                meta_score: 10
              });
            });
          }
        }
        return result;
      };
    })(this);
    CompletionsCache = (function() {

      /*
      * processJson -- function -- handler for defined type of json(citeJson, refJson, etc)
      * return object with fields name, value and (optional) meta, meta_score, score
       */
      function CompletionsCache(processJson) {
        this.getReferences = bind(this.getReferences, this);
        this.lastFetchedUrl = "";
        this.cache = [];
        this.processJson = processJson;
      }

      CompletionsCache.prototype.getReferences = function(url, callback) {
        if (url !== this.lastFetchedUrl) {
          return $.getJSON(url).done((function(_this) {
            return function(data) {
              if (data != null) {
                _this.cache = _this.processJson(data);
                callback(null, _this.cache);
                return _this.lastFetchedUrl = url;
              }
            };
          })(this));
        } else {
          return callback(null, this.cache);
        }
      };

      return CompletionsCache;

    })();

    /*
    * Show popup if token type at the current pos is one of the given array elements.
    * @ (editor) --> editor
    * @ (list of strings) -- allowedTypes
     */
    showPopupIfTokenIsOneOfTypes = function(editor, allowedTypes) {
      var i, len, pos, results, session, token, type;
      if (editor.completer != null) {
        pos = editor.getCursorPosition();
        session = editor.getSession();
        token = session.getTokenAt(pos.row, pos.column);
        if (token != null) {
          results = [];
          for (i = 0, len = allowedTypes.length; i < len; i++) {
            type = allowedTypes[i];
            if (LatexParsingContext.isType(token, type)) {
              editor.completer.showPopup(editor);
              break;
            } else {
              results.push(void 0);
            }
          }
          return results;
        }
      }
    };
    TexCompleter = (function() {
      function TexCompleter() {
        this.getCompletions = bind(this.getCompletions, this);
        this.completeLinebreak = bind(this.completeLinebreak, this);
        this.setCitationsUrl = bind(this.setCitationsUrl, this);
        this.setReferencesUrl = bind(this.setReferencesUrl, this);
        this.setEnabled = bind(this.setEnabled, this);
        this.init = bind(this.init, this);
        this.refCache = new CompletionsCache(processReferenceJson);
        this.citeCache = new CompletionsCache(processCitationJson);
        this.enabled = true;
      }

      TexCompleter.prototype.init = function(editor) {
        var keyboardHandler;
        keyboardHandler = new HashHandler.HashHandler();
        keyboardHandler.addCommand({
          name: "add item in list mode",
          bindKey: {
            win: "enter",
            mac: "enter"
          },
          exec: (function(_this) {
            return function(editor) {
              if (_this.enabled) {
                return _this.completeLinebreak(editor);
              } else {
                return false;
              }
            };
          })(this)
        });
        editor.keyBinding.addKeyboardHandler(keyboardHandler);
        editor.commands.on('afterExec', function(event) {
          var allowCommand, ref;
          allowCommand = ["Return", "backspace"];
          if (ref = event.command.name, indexOf.call(allowCommand, ref) >= 0) {
            return showPopupIfTokenIsOneOfTypes(editor, ["ref", "cite"]);
          }
        });
        return editor.getSession().selection.on('changeCursor', function(cursorEvent) {
          return showPopupIfTokenIsOneOfTypes(editor, ["ref", "cite"]);
        });
      };

      TexCompleter.prototype.setEnabled = function(enabled) {
        return this.enabled = enabled;
      };

      TexCompleter.prototype.setReferencesUrl = function(url) {
        return this.referencesUrl = url;
      };

      TexCompleter.prototype.setCitationsUrl = function(url) {
        return this.citationsUrl = url;
      };

      TexCompleter.prototype.completeLinebreak = function(editor) {
        var cursor, indentString, indexOfBegin, line, tabString;
        cursor = editor.getCursorPosition();
        line = editor.session.getLine(cursor.row);
        tabString = editor.session.getTabString();
        indentString = line.match(/^\s*/)[0];
        indexOfBegin = line.indexOf("begin");
        if (LatexParsingContext.getContext(editor.session, cursor.row, cursor.column) === LIST_STATE && indexOfBegin < cursor.column) {
          if (indexOfBegin > -1) {
            editor.insert("\n" + tabString + indentString + "\\item ");
          } else {
            editor.insert("\n" + indentString + "\\item ");
          }
          return true;
        } else {
          return false;
        }
      };


      /*
       * callback -- this function is adding list of completions to our popup. Provide by ACE completions API
       * @param {object} error -- convention in node, the first argument to a callback
       * is usually used to indicate an error
       * @param {array} response -- list of completions for adding to popup
       */

      TexCompleter.prototype.getCompletions = function(editor, session, pos, prefix, callback) {
        var context, token;
        if (!this.enabled) {
          callback(null, []);
          return;
        }
        token = session.getTokenAt(pos.row, pos.column);
        context = LatexParsingContext.getContext(session, pos.row, pos.column);
        if (LatexParsingContext.isType(token, "ref")) {
          if (this.referencesUrl != null) {
            this.refCache.getReferences(this.referencesUrl, callback);
          }
          return;
        }
        if (LatexParsingContext.isType(token, "cite")) {
          if (this.citationsUrl != null) {
            this.citeCache.getReferences(this.citationsUrl, callback);
          }
          return;
        }
        if ((prefix.length >= 2 && prefix[0] === "\\") || (prefix.length >= 3)) {
          switch (context) {
            case "start":
              callback(null, BASIC_SNIPPETS.concat(LIST_SNIPPET, EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET));
              break;
            case LIST_STATE:
              callback(null, LIST_KEYWORDS.concat(LIST_SNIPPET, EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET, LIST_END_ENVIRONMENT));
              break;
            case EQUATION_STATE:
              callback(null, EQUATION_SNIPPETS);
              break;
            case ENVIRONMENT_STATE:
              callback(null, ENVIRONMENT_LABELS);
              break;
            default:
              callback(null, BASIC_SNIPPETS.concat(LIST_SNIPPET, EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET));
          }
          return;
        }
        callback(null, []);
      };

      return TexCompleter;

    })();
    return TexCompleter;
  });

}).call(this);
