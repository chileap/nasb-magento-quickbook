MagentoQBO.Common =
  init: ->
    @_toast()
    @_collapseButton()
    @_handleCollapseList()
    @_handleBtnDropDown()
    @_handleSelectTag()

  _toast: ->
    dataToast = ''
    if $('#flash_notice').text() != ''
      dataToast = $('#flash_notice').text()
    else if $('#flash_alert').text() != ''
      dataToast = $('#flash_alert').text()
    Materialize.toast(dataToast, 2000)

  _collapseButton: ->
    $( document ).ready( ->
      $(".button-collapse").sideNav();
    )

  _handleBtnDropDown: ->
    $( document ).ready( ->
      $(".dropdown-button").dropdown();
    )

  _handleCollapseList: ->
    $( document ).ready( ->
      $('.collapsible').collapsible();
    )

  _handleSelectTag: ->
    $(document).ready ->
      $('select').material_select()
