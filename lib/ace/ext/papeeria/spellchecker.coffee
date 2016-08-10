define( ->
  # This will be removed and replaced with real data from server.
  # BTW, this is kinda template for data to send from server.
  TEST_JSON_TYPOS = {
    "blablabla": [
      "blah-blah-blah"
      "blabber"
      "blabbed"
      "salable"
    ]
  }


  # Class by now provides words checking (used for highlighting)
  # and also provides corrections list for a given word.
  class SpellChecker
    # By now it's just a stub, but I guess this function will take data from
    # server somehow in future.
    # @return {Object} JSON-list of incorrect words.
    getJson: ->
      return TEST_JSON_TYPOS

    # Check whether token is in JSON incorrect words list.
    # @param {String} token: Token to check.
    # @return {Boolean} False if token is in list, true otherwise.
    check: (token) =>
      return not @getJson()[token]

    # Return corrections list for token if exists.
    # @param {String} token: token to search in corrections list from server.
    # @return {Array}: list of corrections.
    getCorrections: (token) ->
      return if not @check(token) then @getJson()[token]

  return {
    SpellChecker: SpellChecker
  }

)
