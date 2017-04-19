MagentoQBO.Common =
  init: ->
    @_toast()
    @_collapseButton()
    @_handleCollapseList()

  _toast: ->
    dataToast = ''
    if $('#flash_notice').text() != ''
      dataToast = $('#flash_notice').text()
    else if $('#flash_alert').text() != ''
      dataToast = $('#flash_alert').text()
    Materialize.toast(dataToast, 5000)

  _collapseButton: ->
    $( document ).ready( ->
      $(".button-collapse").sideNav();
    )

  _handleCollapseList: ->
    $( document ).ready( ->
      $('.collapsible').collapsible();
    )
