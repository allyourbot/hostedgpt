export default class {
  logLevels = {
    'debug': 0,
    'info': 1,
    'warn': 2,
    'error': 3,
  }

  constructor() {
    this.attributes = this._createAttributeProxy({})
    this.$ = this.attributes // Define '$' as a property of 'this'
    this._haveSetDefaultAttributes = false
    this.$['class'] = this.constructor

    this._analyzeMethods()
    this._wrapMethods()
    this._wrapGettersAndSetters()

    if (typeof this.new === 'function') this.new(...arguments)

    const self = this

    setTimeout(() => this._setAttrDefaultValues(), 0)

    return new Proxy(this, {
      get(target, prop, receiver) {
        const readerProps = self._declarationsFor('attrReader', 'attrAccessor', 'attr').concat(['class'])
        if (readerProps.includes(prop))
          return self._setAttrDefaultValues() && receiver.$[prop]
        else
          return Reflect.get(...arguments)
      },
      set(target, prop, value, receiver) {
        const writerProps = self._declarationsFor('attrWriter', 'attrAccessor').concat(['class'])
        if (writerProps.includes(prop))
          return receiver.$[prop] = value
        else
          return Reflect.set(...arguments)
      }
    })
  }

  _createAttributeProxy(attr) {
    const handler = {
      set: (obj, prop, value) => {
        if (obj[prop] !== value) {
          obj[prop] = value
          const changeHandler = `on${prop.capitalize()}Changed`
          if (typeof this[changeHandler] === 'function') {
            this[changeHandler](value)
          }
        }
        return true // indicates success
      }
    }
    return new Proxy(attr, handler)
  }

  _analyzeMethods() {
    this._prototype = Object.getPrototypeOf(this)
    this._descriptors = Object.getOwnPropertyDescriptors(this._prototype)
    this._properties = Object.keys(this._descriptors)
    this._allMethods = this._properties.filter(prop =>  (typeof this._descriptors[prop].value === 'function' || this._descriptors[prop].get || this._descriptors[prop].set) && prop !== 'constructor')
    this._allMethodsExceptGetterAndSetter = this._allMethods.filter(prop => !this._descriptors[prop].get && !this._descriptors[prop].set)
    this._getterMethods = this._allMethods.filter(prop => this._descriptors[prop].get)
    this._setterMethods = this._allMethods.filter(prop => this._descriptors[prop].set)
    this._getterAndSetterMethods = this._allMethods.filter(prop => this._descriptors[prop].get || this._descriptors[prop].set)
    this._callableMethodsExceptUppercase = [...this._allMethodsExceptGetterAndSetter.excluding('new').filter(prop => prop[0] && prop[0] === prop[0].toLowerCase()), 'log']
  }

  _wrapMethods() {
    this._allMethodsExceptGetterAndSetter.forEach(func => {
      const originalMethod = this[func]
      const methodStr = originalMethod.toString()
      const isAsync = methodStr.startsWith('async ')

      const args = methodStr.substring(methodStr.indexOf('(')+1, methodStr.indexOf(')')).split(',')
      const methodBody = methodStr.substring(methodStr.indexOf('{')+1).trim().slice(0, -1)
      const body = `
        {
          const $ = this.attributes;
          ${this._callableMethodsExceptUppercase.map(func => 'const '+func+' = this.'+func+'.bind(this);').join("\n")}
          ${this._getterMethods.map(func => 'const ' + func + ' = (v) => { return (typeof v == "undefined") ? this.'+func+' : this.'+func+' = v };').join("\n")}
          this._methodLog('${func}', arguments, this.${func}.length);

          ${methodBody}
        }
      `
      if (isAsync)
        this[func] = new Function(...args, `return (async function() { ${body} }).apply(this, arguments)`)
      else
        this[func] = new Function(...args, body)
    })
  }

  _wrapGettersAndSetters() {
    this._getterAndSetterMethods.forEach(func => {
      // if the function dot wrapped is true then skip this iteraction of the foreach loop

      if (this._descriptors[func].get) {
        const methodBody = this._descriptors[func].get.toString().match(/{([\s\S]*)}/)[1].trim()
        const body = `
          {
            const $ = this.attributes;
            ${this._callableMethodsExceptUppercase.map(func => 'const '+func+' = this.'+func+'.bind(this);').join("\n")}
            ${this._getterMethods.map(func => 'const '+func+' = (v) => { return (typeof v == "undefined") ? this.'+func+' : this.'+func+' = v };').join("\n")}
            this._methodLog('${func}', [], 0)

            ${methodBody}
          }
        `
        const newGetter = new Function(body).bind(this)
        Object.defineProperty(this, func, {
          get: newGetter,
          configurable: true,
          enumerable: true
        })
      }

      if (this._descriptors[func].set) {
        const methodStr = this._descriptors[func].set.toString()
        const arg = methodStr.match(/\(([^)]*)\)/)[1].trim()
        const methodBody = methodStr.match(/{([\s\S]*)}/)[1].trim()
        const body = `
          {
            const $ = this.attributes;
            ${this._callableMethodsExceptUppercase.map(func => 'const '+func+' = this.'+func+'.bind(this);').join("\n")}
            ${this._getterMethods.map(func => 'const ' + func + ' = (v) => { return (typeof v == "undefined") ? this.'+func+' : this.'+func+' = v };').join("\n")}
            this._methodLog('${func}', [${arg}], 1);

            ${methodBody}
          }
        `
        const newSetter = new Function(arg, body).bind(this)
        Object.defineProperty(this, func, {
          set: newSetter,
          configurable: true,
          enumerable: true
        })
      }
    })
  }

  _methodLog(name, args, numArgs) {
    const methodName = name.replace(/^_/, '') // turn _calculate into just calculate
    const logDirective = `log_${methodName}`
    let argSummary = []
    for (let i = 0; i < numArgs; i++) {
      let arg = args[i]
      if (typeof arg === 'number' || typeof arg === 'string' || typeof arg === 'boolean')
        argSummary.push(arg)
      else if (typeof arg === 'undefined')
        argSummary.push('undefined')
      else if (arg === null)
        argSummary.push('null')
      else if (typeof arg === 'function')
        argSummary.push('function')
      else if (typeof arg === 'symbol')
        argSummary.push(arg.toString())
      else if (Array.isArray(arg))
        argSummary.push('array')
      else if (typeof arg === 'object' && arg !== null && Object.getPrototypeOf(arg) === Object.prototype)
        argSummary.push('obj')
      else argSummary.push('class')
    }

    let level = 'debug'
    if (this._declarationsFor('log').includes(methodName)) {
      let logDirective = this._declaration('log', methodName)
      level = (typeof logDirective === 'string') ? logDirective : 'info'
    }

    this.log(`${name}(${argSummary.join(',')})`, level)
  }

  log(str, level = 'info') {
    let logLevel
    // if (node.env.isTest)
    //   logLevel = 'error'
    // else
      logLevel = this._declarationsFor('logLevel').first() || 'error'
    if (this.logLevels[level] >= this.logLevels[logLevel]) {
      if (node.env.isTest)
        process.stdout.write(`${this.$['class']?.to_s}: ${str}\n`)
      else {
        let c = this.$['class']?.to_s ?? ''
        if (c.includes('Control') && str.includes('(') && str[0] == str[0].upcase() && str[0] == '_') {
          c = c.replace('Control', '')
          let pieces = str.split('(')
          console.log(`${pieces[0]}.${c} (${pieces[1]}`)
        } else
          console.log(`${this.$['class']?.to_s}: ${str}`)
      }
    }
  }

  _setAttrDefaultValues() {
    // The default value of attr_* variables cannot be accessed inside the constructor. Most of the time,
    // the setTimeout with 0 hack will get it to happen at the end of the constructor but more advanced
    // class stuff can still end up skipping that. That's why we also call this within the getter as a backup.
    if (this._haveSetDefaultAttributes) return true

    const attrProps = this._declarationsFor('attr')
    attrProps.forEach(prop => {
      if (typeof this[`attr_${prop}`] != 'undefined' && this.$[prop] === undefined) this.$[prop] = this[`attr_${prop}`]
    })

    this._haveSetDefaultAttributes = true
    return true
  }

  _declarationsFor(...prefixes) {
    return Object.keys(this)
        .filter(prop => prefixes.some(prefix => prop.startsWith(prefix) && prop.includes('_')))
        .map(prop => prop.split('_').splice(1))
        .flat()
  }

  _declaration(declaration, name) {
    return this[`${declaration}_${name}`]
  }
}
