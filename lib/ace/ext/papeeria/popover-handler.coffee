define((require, exports, module) ->
  class PopoverHandler
    show: (jqPopoverContainer, options) ->
      popoverPosition = jqPopoverContainer.position()
      popoverPosition.top += 24
      jqPopoverContainer.css(popoverPosition)
      jqPopoverContainer.popover(options)
      jqPopoverContainer.popover("show")
      return

    hide: (jqPopoverContainer) ->
      jqPopoverContainer.popover("destroy")
)
