
class t

  blockregex = /\{\{\s*?(([@!>]?)(.+?))\s*?\}\}(([\s\S]+?)(\{\{\s*?:\1\s*?\}\}([\s\S]+?))?)\{\{\s*?\/(?:\1|\s*?\3\s*?)\s*?\}\}/g
  valregex = /\{\{\s*?([<&=%\+])\s*?(.+?)\s*?\}\}/g

  constructor: (template) ->

    @scrub = (val) =>
      return new Option(val).innerHTML.replace(/["']/g, '&quot;')

    @get_value = (vars, key) =>
      parts = key.split('.')
      while parts.length
        return false if parts[0] not of vars
        vars = vars[parts.shift()]

      return (if typeof vars is 'function' then vars() else vars)

    @t = template
    @temp = []
    @children = {}
    return @

  template: (@t) ->
    return @

  parse: (fragment, vars) =>
    @temp = []
    if not vars?
      vars = fragment
      fragment = @t

    return fragment.replace(blockregex, (_, __, meta, key, inner, if_true, has_else, if_false) =>
      val = @get_value(vars, key)
      temp = ''

      if not val
        return (if meta is '!' then @parse(inner, vars) else (if has_else then @parse(if_false, vars) else ''))

      if not meta
        return @parse(if has_else then if_true else `inner, vars`)

      if meta is '@'
        for k, v of val
          if val.hasOwnProperty(k)
            temp += @parse(inner, {_key: k, _val: v})

      if meta is '>'
        if Array.isArray(val) or val.constructor.name is 'ListField'
          temp += @parse(inner, item) for item in val
        else temp += @parse(inner, val)

      return temp
    ).replace(valregex, (_, meta, key) =>
      return @temp[parseInt(key)-1] if meta is '&'
      return (val = (@children[key] ||= new window[key]()).parse(vars)) if meta is '+'
      val = @get_value(vars, key)
      @temp.push(val) if meta is '<'
      return (if val? then (if meta is '%' then @scrub(val) else val) else '')
    )

window.t = t
