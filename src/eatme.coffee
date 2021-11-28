if window.jQuery?
  $ = jQuery
else
  throw "EatMe requires is jQuery to be loaded first."

window.qqq = (a)->
  window.q = a
  return a

window.say = (a...)->
  for o in a
    console.dir o, depth: 10
  return a[0]

class window.EatMe

  @configs: {}
  @objects: []

  @conf: (conf)->
    conf = new EatMe.Config(conf)
    slug = conf.slug
    throw "Eatme conf '#{slug}' already exists" \
      if @configs[slug]?
    @configs[slug] = conf
    return slug

  @init: ({elem, conf})->
    if elem instanceof jQuery
      $elem = elem
    else if _.isString(elem) or elem instanceof Element
      $elem = $(elem)
    else
      throw "Bad 'elem' argument for EatMe.init"

    if not (config = @configs[conf])
      throw "No EatMe.Config named '#{conf}' found"

    sub_class = @

    $elem.each(->
      elem = @
      eatme_object = new sub_class(elem, config)
      sub_class.objects.push(eatme_object)
    )

  init: ->

  constructor: (@from, @conf)->
    @init()

    @make_root()

    @make_cols()

    @start()

  make_root: ()->
    $from = $(@from)

    if $from[0].tagName != 'PRE'
      throw "Can only make EatMe from '<pre>'"

    @root = $(@conf.html)
      .addClass('eatme-container')

  make_cols: ->
    @panes = $('<div hidden>').appendTo(@root)
    cols = @conf.cols
    size = 12 / cols

    for col in [1 .. cols]
      $col = @make_col(size)
      @root.append($col)

    @$panes = {}
    for pane in @conf.pane
      if (column = pane.colx)?
        $col = $(@root.find(".eatme-col")[column - 1])
        @$panes[pane.slug] = $pane = @make_pane(pane.slug)
          .appendTo($col)
        @setup_pane($pane)

    self = @
    @root.find('.eatme-col').each ->
      $col = $(@)
      if $col.find('.eatme-pane').length == 0
        self.make_empty_pane()
          .appendTo($col)

    # @make_resizable()

  start: ->
    $(@from).replaceWith(@root)

  make_resizable: ->
    @root.splitobj = Split @root.find('.col').toArray(),
      elementStyle: (dimension, size, gutterSize)->
        # $(window).trigger('resize')
        return \
          'flex-basis': "calc(#{size}% - #{gutterSize}px)"
      gutterStyle: (dimension, gutterSize)->
        return 'flex-basis': "#{gutterSize}px"
      sizes: [20,60,20]
      minSize: 150
      gutterSize: 6
      cursor: 'col-resize'

  make_col: (size)->
    $("""<div class="eatme-col col col-lg-#{size}">""")

  switch_pane: ($old, $new)->
    self = @
    @root.find('.eatme-col .eatme-pane').each ->
      $pane = $(@)
      if $pane.attr('id') == $new.attr('id')
        $replaced = $pane.replaceWith(self.make_empty_pane())
        if not $replaced.attr('id').match(/^empty-/)
          self.panes.append($replaced)

    @panes.append(
      $old.replaceWith($new)
        .appendTo(@panes)
    )

    @setup_pane($new)

  setup_pane: ($pane)->
    self = @
    pane_id = $pane.attr('id')
    if pane_id.match(/^empty-/)
      pane_id = 'empty'

    $pane.find('select')
      .val(pane_id)
      .attr('pane', pane_id)

    copy_button = $pane.find('.eatme-btn-copy-text')[0]
    $pane.clipboard = new ClipboardJS copy_button,
      target: (btn)-> self.copy_text($(btn))

    conf = @conf.panes[pane_id]
    if (call = conf.call)?
      [func, from] = call
      calls =
        @root.find(".eatme-pane-" + from)[0].calls ||= []
      calls.push([func, $pane])

    pane = $pane[0]
    conf = pane.eatme
    if conf.type == 'input' and not pane.cm?
      $textarea = $pane.find('textarea')
      text = if @input? then @input else $(@from).text()

      if (text)
        $textarea.text(text)
      else
        $textarea.text("\n")

      setTimeout ->
        pane.cm = cm = CodeMirror.fromTextArea $textarea[0],
          lineNumbers: true
          tabSize: 4

        do_calls = ->
          text = cm.getValue()
          if self.change?
            self.change(text, pane)
          results = []
          for call in pane.calls
            [func, $to] = call
            results.push(self.call(func, text, $to))
          results

        cm.on('change', $.debounce(400, do_calls))

        setTimeout ->
          do_calls()
          cm.focus()
          cm.setCursor
            line: 0
            ch: 0
        , 200
      , 100

  call: (func, text, $to)->
    func = func.replace(/-/g, '_')

    try
      show = @[func](text)
      if _.isString(show)
        show = output: show
    catch e
      error = (e.stack || e.msg || e).toString()
      show = error: error

    @show($to, show)

  show: ($pane, show)->
    pane = $pane[0]

    if (html = show.html)?
      $box = pane.$html.html(html)
    else if (markdown = show.mark)?
      $box = pane.$html.html(marked.parse(markdown))
    else if (error = show.error)?
      $box = pane.$error.text(error)
    else if (output = show.output)?
      $box = pane.$output.text(output)
    else
      throw "Invalid show value: '#{show}'"

    $show = $pane.children().last()
    $show.replaceWith($box) unless $show[0] == $box[0]

  @empty: 1
  make_empty_pane: ->
    num = EatMe.empty++
    slug = "empty-#{num}"
    pane =
      name: 'Empty'
      slug: slug
      type: 'text'

    return @make_pane(pane)

  make_pane: (pane)->
    if _.isString(pane)
      pane = @conf.panes[pane] or
        throw "Unknown pane id '#{pane}'"

    $pane = $("""
      <div
        id="#{pane.slug}"
        class="eatme-pane eatme-pane-#{pane.slug}"
      >
    """)
      .append(@make_nav())

    $pane[0].eatme = pane
    $pane[0].$output = $('<pre class="eatme-box">')
    $pane[0].$error = $('<pre class="eatme-box eatme-error">')
    $pane[0].$html = $('<div class="eatme-box">')

    if pane.type == 'input'
      $box = $('<textarea class="eatme-box">')
    else if pane.type == 'error'
      $box = $('<pre class="eatme-box eatme-errors">')
    else
      $box = $('<pre class="eatme-box">')

    if pane.load?
      $box.load(pane.load)
    else
      $box.html(pane.text || '')

    $pane.append($box)

    return $pane

  make_nav: ->
    return $('<div class="eatme-nav">')
      .append(@make_toolbar())
      .append(@make_pane_select())

  make_pane_select: ->
    self = @
    $select = $("""
      <select class="eatme-select form-select form-select-lg">
        <option value="empty">Choose a Pane</option>
      </select>
    """)
    $select.on('change', -> self.select_changer(@.value, $select))

    for pane in @conf.pane
      $("""<option value="#{pane.slug}">#{pane.name}</option>""")
        .appendTo($select)

    return $select

  select_changer: (id, $select)->
    $old = $select.closest('div.eatme-pane')
    $new = $("##{id}")
    if $new.length != 1
      if id == 'empty'
        $new = @make_empty_pane()
      else
        $new = @make_pane(id)
    @switch_pane($old, $new)

  #----------------------------------------------------------------------------
  # Toolbar button handlers
  #----------------------------------------------------------------------------
  add_pane: ($button, e)->
    $col = $button.closest('.eatme-col')
    panes = $col.find('div.eatme-pane').length
    if panes < 4
      e.stopPropagation()
      $pane = @make_empty_pane()
      $col.append($pane)

  close_pane: ($button)->
    $pane = $button.closest('.eatme-pane')
    $col = $pane.closest('.eatme-col')
    if $col.find('.eatme-pane').length > 1
      $pane.appendTo(@panes)

  move_pane: ($button)->
    $pane = $button.closest('.eatme-pane')
    $pane.next().after($pane)

  add_col: ($button)->
    $col = $button.closest('.eatme-col')
    $cols = $col.parent().find('.eatme-col')
    cols = $cols.length
    return unless cols < 4
    size_old = 12 / cols++
    size_new = 12 / cols
    $cols.toggleClass("col-lg-#{size_old} col-lg-#{size_new}")
    @make_col(size_new).insertAfter($col)

  close_col: ($button)->
    $col = $button.closest('.eatme-col')
    $cols = $col.parent().find('.eatme-col')
    cols = $cols.length
    return unless cols > 1
    size_old = 12 / cols--
    size_new = 12 / cols
    $col.find('.eatme-pane').appendTo(@panes)
    $col.remove()
    $cols.toggleClass("col-lg-#{size_old} col-lg-#{size_new}")

  move_col: ($button)->
    $col = $button.closest('.eatme-col')
    $col.next().after($col)

  copy_text: ($button)->
    $textarea = $button
      .closest('.eatme-pane')
      .find('textarea')
    return $textarea[0] if $textarea.length > 0

  clear_text: ($button)->
    $button
      .closest('.eatme-pane')
      .find('textarea')
      .val('')
      .focus()

  zoom_in: ($button, e)->
    e.stopPropagation()
    $pane = $button.closest('.eatme-pane')
    size = $pane.css('font-size').replace(/px$/, '')
    return unless size < 25
    size++
    $pane.css('font-size', "#{size}px")

  zoom_out: ($button, e)->
    e.stopPropagation()
    $pane = $button.closest('.eatme-pane')
    size = $pane.css('font-size').replace(/px$/, '')
    return unless size > 7
    size--
    $pane.css('font-size', "#{size}px")

  toggle_error: ($button)->
    $pane = $button.closest('.eatme-pane')
    if ($error = $pane.find('.eatme-box-error')).length == 0
      $error = $('<pre class="eatme-box-error" style="display:none">')
        .appendTo($pane)
      if (error = $pane[0].error)?
        $error.text(error)

    $pane.find('.eatme-box, .eatme-box-error')
      .toggle()

  make_toolbar: ->
    self = @

    $toolbar = $(EatMe.toolbar_div)
    $ul = $toolbar.find('ul')

    for line in EatMe.toolbar
      $li = $('<li>')
        .appendTo($ul)
      for btn in line
        @make_button(btn, $toolbar)
          .appendTo($li)

    return $toolbar

  make_button: (id, $tools)->
    btn = EatMe.buttons[id]

    $btn = $("""
      <a
        class="eatme-btn-#{id}"
        title="#{btn.name}">
        <i class="bi-#{btn.icon}" />
      </a>
    """)

    if not btn.dead?
      func = btn.func || id.replace(/-/g, '_')
      $btn.attr('href': '#')
      self = @
      func = @[func]
      $tools.on(
        'click',
        ".eatme-btn-#{id}",
        (e)-> func.call(self, $(@), e, self)
      )

    return $btn

  add_button: (id, button, row, col)->
    row ?= EatMe.toolbar.length
    button.code = true
    EatMe.buttons[id] = button
    EatMe.toolbar[row - 1].push(id)

  @toolbar_div: """
    <div class="eatme-btns dropdown">
      <button
        class="btn btn-default dropdown-toggle eatme-toolbar-btn"
        type="button"
        data-toggle="dropdown"
        title="Pane toolbar"
      ></button>

      <ul class="dropdown-menu">
      </ul>
    </div>
  """

  @toolbar: [
    [
      'toggle-error'
      'edit-pane'
      'copy-text'
      'clear-text'
      'zoom-in'
      'zoom-out'
    ]
    [
      'pause-auto'
      'start-auto'
      'permalink'
      'settings'
    ]
    [
      'add-pane'
      'close-pane'
      'move-pane'
    ]
    [
      'add-col'
      'close-col'
      'move-col'
    ]
  ]

  @buttons:
    'toggle-error':
      name: 'Toggle Error Display'
      icon: 'exclamation-square'
    'edit-pane':
      name: 'Edit this pane'
      icon: 'pencil-square'
      dead: true
    'copy-text':
      name: 'Copy pane text'
      icon: 'files'
    'clear-text':
      name: 'Clear pane text'
      icon: 'x-square'
    'zoom-in':
      name: 'Increase font size'
      icon: 'zoom-in'
    'zoom-out':
      name: 'Decrease font size'
      icon: 'zoom-out'
    'pause-auto':
      name: 'Pause auto run'
      icon: 'pause-circle'
      dead: true
    'start-auto':
      name: 'Start auto run'
      icon: 'play-circle'
      dead: true
    'permalink':
      name: 'Get permalink'
      icon: 'link'
      dead: true
    'settings':
      name: 'Pane settings'
      icon: 'gear'
      dead: true
    'add-pane':
      name: 'Add new pane to column'
      icon: 'plus-square'
    'close-pane':
      name: 'Close this pane'
      icon: 'dash-square'
    'move-pane':
      name: 'Move this pane down one'
      icon: 'arrow-down-square'
    'add-col':
      name: 'Add new column to right'
      icon: 'plus-square-fill'
    'close-col':
      name: 'Close this column'
      icon: 'dash-square-fill'
    'move-col':
      name: 'Move this column right'
      icon: 'arrow-right-square-fill'

class EatMe.Config
  constructor: (conf)->
    [@src, @trg, @lvl] = [conf, @, 'top level']

    @required_slug('slug')
    @optional_num('cols', 1, 4)
    @required_str('html')

    @pane = []
    @panes = {}

    @set_panes()

    delete @src
    delete @trg
    delete @lvl

  set_panes: ->
    if not (objs = @src.pane)? or not _.isArray(objs)
      throw "EatMe.Config requires 'pane' array"

    for obj in objs
      if not _.isPlainObject(obj)
        throw "Each element of 'pane' array must be an object"
      pane = {}
      [@src, @trg, @lvl] = [obj, pane, 'pane object']
      @required_str('name')
      @required_slug('slug')
      pane.type = null
      @set_call()
      @optional_str('mark')
      @optional_str('html')
      @optional_num('colx', 1, 4)

      @set_type()

      @pane.push(pane)
      @panes[@trg.slug] = pane

  set_type: ->
    type = @src.type
    if not type?
      if @trg.call?
        type = 'text'
      else if @trg.mark? or @trg.html
        type = 'html'
      else
        say @src
        throw "No 'type' value set"

    @trg.type = type

  set_call: ->
    return unless (call = @src.call)?
    if (not _.isArray(call)) or not
       (_.isString(call[0]) and _.isString(call[1]))
      throw "EatMe.Config 'call' value must be array of strings"
    @trg.call = call

  required: (name)->
    if not (value = @src[name])?
      throw "Config value '#{name}' required for #{@lvl}"
    return value

  required_str: (name)->
    value = @required(name)
    @validate_str(value, name)
    @trg[name] = value

  required_slug: (name)->
    value = @required(name)
    @validate_slug(value, name)
    @trg[name] = value

  optional_str: (name)->
    return unless (value = @src[name])?
    @validate_str(value, name)
    @trg[name] = value

  optional_num: (name, min, max)->
    return unless (value = @src[name])?
    if (not _.isNumber(value)) or value < min or value > max
      throw "Invalid value '#{value}' for '#{name}', must be a number from #{min} to #{max}"
    @trg[name] = value

  validate_str: (value, name)->
    if not _.isString(value)
      throw "Invalid value '#{value}' for '#{name}' in '#{@lvl}', must be a string"

  validate_slug: (value, name)->
    if not value.match(/^[-a-z0-9]+$/)
      throw "Invalid slug value '#{value}'"
