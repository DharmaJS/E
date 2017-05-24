###
    [E.JS]
    A descriptive way to mess around with advanced javascript.

    It's goal is to create a replacement for frameworks such as JQuery, Backbone,
    React, Angular, ... with an approach closer to Vanilla.js and with a small footprint.

    E.JS makes it easier to:
        create elements
        manipulate DOM
        componetize
        change DOM by reference
        create plugins
        make AJAX requests

    TODO:
        - event handling and aggregation
        - change of properties and attributes via function
        - wrap
        - siblings before and after
        - implement functions from umbrella
###

class e
    @fn : {}# stores external functions to run over e.js

    constructor: (params, element) ->

        ## CALLBACK
        # ready
        if typeof(params) == "function"
            e.ready(params)
            return null

        ## DOM CREATION
        # create multiple
        else if Object.prototype.toString.call(params) == '[object Array]'
            for param in params
                e(param, element)


        # returns instance of Element with e.js methods
        if params instanceof Element
            aux = params

        # element creation - returns a single element
        else if typeof(params) == 'object'
            # create element or get one to be altered
            if element?
                aux = element
            else
                aux = document.createElement(params['tag'])

            # data
            if params['data']?
                for data, value of params['data']
                    aux.dataset[data] = value

            # events
            for event, value of params['events']
                aux.addEventListener(
                    event,
                    value
                )

            # properties
            for prop, value of params['props']
                aux[prop] = value

            # attributes
            for attr, value of params['attrs']
                if value != null && value != ""
                    aux.setAttribute(
                        attr,
                        value
                    )

            # append children
            if params['children']?
                for child in params['children']
                    aux.append(child)

            # style
            for style, value of params['styles']
                aux.style[style] = value

            # append to context, if defined
            # if element?
            #     element.appendChild aux

        # query selector - ALWAYS returns an array
        else if typeof(params) == 'string'
            # set context
            if element?
                context = element
            else
                context = document

            aux = context.querySelectorAll(params)


        ## DOM MANIPULATION
        # set attribute
        aux.attr = () ->
            # this.setAttribute(arguments)
            Element.prototype.setAttribute.apply(this, arguments)
            return this

        # smaller append
        aux.append = () ->
            # if typeof(arguments[0]) == "object"
            #     for element in arguments[0]
            #         this.appendChild(element)
            # else
            Element.prototype.appendChild.apply(this, arguments)
            return this

        # innerHTML
        aux.html = () ->
            this.innerHTML = ""

            if typeof(arguments[0]) == "string"
                this.innerHTML = arguments[0]
            else
                this.append(arguments[0])
            return this

        # better dataset function
        aux.data = () ->
            if this.dataset[arguments[0]]?
                return this.dataset[arguments[0]].split(",")
            else
                return null

        # easier remove
        aux.remove = () ->
            this.parentNode.removeChild(this)

        # query selector based on an element. same as e("selector", this)
        aux.find = () ->
            return this.querySelectorAll(arguments[0])

        # clone element
        aux.clone = () ->
            return this.cloneNode(true)

        # return element value on demand
        aux.val = () ->
            # GET
            if !arguments[0]?
                if this.tagName == "SELECT"
                    values = []
                    for op in this.options
                        # no option selected, so consider the first one
                        if this.selectedIndex < 0
                            return op.value

                        # if any selected
                        if op.selected
                            if this.type == "select-one"
                                return op.value
                            else
                                values.push op.value

                    # select element always return array
                    return values
                else
                    return this.value

            # SET
            else
                if this.tagName == "SELECT"
                    # turn into array if it's not
                    if typeof(arguments[0]) != "array"
                        arguments[0] = [arguments[0]]

                    # set selected options
                    for value in arguments[0]
                        for op in this.options
                            if op.value == value
                                op.selected = true
                            else
                                op.selected = false
                else
                    this.value = arguments[0]

                return this

        # add plugin funcitons
        for key, value of e.fn
            aux[key] = value

        return aux

    ###
        Merge two or more objects. Returns a new object.
        @public
        @static
        @param {Boolean}  deep     If true, do a deep (or recursive) merge [optional]
        @param {Object}   objects  The objects to merge together
        @returns {Object}          Merged values of defaults and options
    ###
    @extend = () ->
        # Setup extended object
        extended = {}

        # Merge the object into the extended object
        merge = (obj) ->
            for prop of obj
                if Object::hasOwnProperty.call(obj, prop)
                    extended[prop] = obj[prop]
            return

        # Loop through each object and conduct a merge
        i = 0
        while i < arguments.length
            obj = arguments[i]
            merge obj
            i++
        extended


    @ready: (event) ->
        window.onload = event


    # ajax requests
    @fetch = (options) ->
        # Merge user options with defaults
        options = e.extend(
            {
                type: 'GET'
                url: null
                data: {}
                callback: null
                contentType: 'application/x-www-form-urlencoded'
                responseType: 'text',
                events: {
                    success: (response) ->
                    error: (response) ->
                },
                async: true
            },
            options or {}
        )

        # create ajax object
        request = new XMLHttpRequest

        # Setup our listener to process compeleted requests
        request.onreadystatechange = (->
            # Only run if the request is complete
            if request.readyState != 4
                return
            else
                if request.status >= 200 and request.status < 300
                    options.events.success(request.responseText, request)
                else
                    options.events.error(request.responseText, request)

            return request
        )

        # Send our HTTP request
        request.open(options.type, options.url, options.async)
        request.setRequestHeader 'Content-type', options.contentType
        if options.async
            request.responseType = options.responseType
        request.send (
            (obj) ->
                encodedString = ''
                for prop of obj
                    if obj.hasOwnProperty(prop)
                        if encodedString.length > 0
                            encodedString += '&'
                        encodedString += encodeURI(prop + '=' + obj[prop])
                encodedString
        )(options.data)

        return request
