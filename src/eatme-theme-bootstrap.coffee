EatMe.theme.bootstrap =
class EatMe.Theme.Bootstrap extends EatMe.Theme
  eatme: (o)->
    """\
    <div class="row eatme">
    </div>
    """

  pane: ({name, slug, html})->
    """\
    <div class="#{o.slug} col-sm mh-100">
    <h4>#{o.name}</h4>
    #{o.html}
    </div>
    """

  input: ({slug, data})->
    """\
    <textarea class="#{slug}-input">#{data}</textarea>
    """

  output: ({slug, data})->
    """\
    <pre class="#{slug}-output">{data}</pre>
    """

  error: ({slug, data})->
    """\
    <pre class="#{slug}-output">{data}</pre>
    """
