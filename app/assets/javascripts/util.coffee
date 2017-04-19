MagentoQBO.Util =
  capitalize: (value) ->
    value.replace /(^|\s)([a-z])/g, (m, p1, p2) ->
      p1 + p2.toUpperCase()

  delimiter: (value) ->
   value.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")
