local Animate = {
    timescale = 1,
    easing = {
        linear = function(t)
            return t
        end,
        quadraticInOut = function(t)
            t = t * 2
            if t < 1 then
                return 0.5 * t * t
            end
            t = t - 1
            return -0.5 * (t * (t - 2) - 1)
        end,
        cubicIn = function(t)
            return t * t * t
        end,
        cubicOut = function(t)
            t = t - 1
            return t * t * t + 1
        end,
        cubicInOut = function(t)
            t = t * 2
            if t < 1 then
                return 0.5 * t * t * t
            end
            t = t - 2
            return 0.5 * (t * t * t + 2)
        end,
        elasticOut = function(t)
            if t == 0 then
                return 0
            end

            if t == 1 then
                return 1
            end
            return 0.4 * 2 ^ (-10 * t) * math.sin((t - 0.1) * 5 * math.pi) + 1
        end,
        backOut = function(t)
            local s = 1.70158
            t = t - 1
            return t * t * ((s + 1) * t + s) + 1
        end
    }
}

Animate.mt = {
    running = false,
    tick = 0,
    _tick = 0,
    delay = 0,
    _delay = nil,
    duration = 1,
    callback = function()
    end,
    done = function()
    end,
    next = nil,
    easing = Animate.easing.linear
}

function Animate.new(o)
    o = o or {}
    setmetatable(o, Animate.mt)
    table.insert(Animate, o)
    if o._delay then
        o.delay = o._delay
    else
        o._delay = o.delay -- save original value
    end
    return o
end

function Animate.update(dt)
    local remove = {}

    for i, a in ipairs(Animate) do
        if a._tick > 0 then
            a._tick = a._tick - 1
        else
            if a:update(dt) then
                table.insert(remove, i)
            end
        end
    end

    if #remove > 0 then
        for i = #remove, 1, -1 do
            table.remove(Animate, remove[i])
        end
    end
end

function Animate.animateTo(values, callback)
    local fromto = {}
    local fromtoVals = {}

    if #values == 2 and type(values[1]) == "number" and type(values[2]) ==
        "number" then
        table.insert(fromto, {values[1], values[2]})
        table.insert(fromtoVals, 0)
    else
        for _, val in ipairs(values) do
            if type(val) ~= "table" then
                error("Invalid argument input")
            end

            table.insert(fromto, val)
            table.insert(fromtoVals, 0)
        end
    end

    return function(t)
        for i, val in ipairs(fromto) do
            fromtoVals[i] = val[1] + (val[2] - val[1]) * t
        end

        callback(unpack(fromtoVals))
    end
end

function Animate.mt.start(a)
    a.running = true
    a._tick = 1
    return a
end

function Animate.mt.stop(a)
    a.running = false
    return a
end

function Animate.mt.add(a, animation)
    a.next = animation
    return animation
end

function Animate.mt.update(a, dt)
    if not a.running then
        return false
    end

    a.tick = a.tick + dt * Animate.timescale

    if a.delay > 0 then
        if a.tick >= a.delay then
            a.tick = a.tick - a.delay
            a.delay = 0
        else
            return false
        end
    end

    if a.tick >= a.duration then
        a.tick = a.duration
    end

    local t = a.easing(a.tick / a.duration)

    a.callback(t)

    if t == 1 then
        a.done()

        if a.next then
            a.next:start()
        end

        return true
    end

    return false
end

Animate.mt.__index = Animate.mt
Animate.mt.__add = Animate.mt.add

return Animate
