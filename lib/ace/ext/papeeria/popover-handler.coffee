define((require, exports, module) ->
  {
    show: (jqPopoverContainer, options) ->
      jqPopoverContainer.css($("textarea.ace_text-input").position())
      popoverPosition = jqPopoverContainer.position()
      popoverPosition.top += 24
      jqPopoverContainer.css(popoverPosition)
      jqPopoverContainer.popover(options)
      jqPopoverContainer.popover("show")
      return

    hide: (jqPopoverContainer) ->
      jqPopoverContainer.popover("destroy")
  }
)
