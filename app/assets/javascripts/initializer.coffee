MagentoQBO.Initializer =
  exec: (pageName) ->
    if pageName && MagentoQBO[pageName]
      MagentoQBO[pageName]['init']()

  currentPage: ->
    return '' unless $('body').attr('id')

    bodyId      = $('body').attr('id').split('-')
    action      = MagentoQBO.Util.capitalize(bodyId[1])
    controller  = MagentoQBO.Util.capitalize(bodyId[0])
    controller + action

  init: ->
    MagentoQBO.Initializer.exec('Common')
    if @currentPage()
      MagentoQBO.Initializer.exec(@currentPage())

$(document).on 'ready page:load', ->
  MagentoQBO.Initializer.init()
