#
# DRAW AREA
# A draw area is the low-level canvas where we can draw our wheel

# widget definition
type DrawArea{n}
    canvas
    coords
    can_draw
    first_click
end

# outer constructor for DrawArea
# n     size of the window
DrawArea(n::Int64) = begin
	# construct Gtk canvas
	canvas = Gtk.GtkCanvas(n,n)
    setproperty!(canvas,:name,"WheelCanvas")

	# construct draw area
	draw_area = DrawArea{n}(canvas,zeros(Float64,0,2),false,true)
    @guarded draw(canvas) do widget
        redraw(draw_area) # to ensure that canvas is drawn on startup
    end

    # attach actions
    canvas.mouse.button1press = @guarded (widget, event) -> at_mouse_button1press(draw_area, event)
    canvas.mouse.button1motion = @guarded (widget, event) -> at_mouse_button1motion(draw_area, event)
    canvas.mouse.motion = @guarded (widget, event) -> at_mouse_motion(draw_area, event)
    canvas.mouse.button3press = @guarded (widget, event) -> at_mouse_button3press_wheel(draw_area, event)

	return draw_area
end

# redraw canvas
function redraw(d::DrawArea)
    # get height and width of canvas
    h = height(d.canvas)
    w = width(d.canvas)
    # get Cairo context
    ctx = getgc(d.canvas)
    # draw canvas
    set_source_rgb(ctx, 1, 1, 1)
    rectangle(ctx, 0, 0, w, h)
    fill(ctx)
    # draw border
    set_dash(ctx, Vector{Float64}())
    set_source_rgb(ctx, 0, 0, 0)
    set_line_width(ctx, 3)
    rectangle(ctx, 0, 0, w, h)
    stroke(ctx)
    # draw axle
    set_line_width(ctx, 2)
    arc(ctx, w/2, h/2, h/100, 0, 2pi)
    fill(ctx)
    # draw all coords
    set_source_rgb(ctx, 0, 0, 0)
    for i = 2:size(d.coords,1)
        move_to(ctx, d.coords[i,1], d.coords[i,2])
        line_to(ctx, d.coords[i-1,1], d.coords[i-1,2])
    end
    stroke(ctx)
end

# implementation of all actions
function at_mouse_button1press(d::DrawArea, event)
    if d.first_click
        d.can_draw = true
        d.first_click = false
    end
    if d.can_draw
        d.coords = vcat(d.coords,[event.x event.y])
        redraw(d)
        reveal(d.canvas)
    end
end

at_mouse_button1motion(d::DrawArea, event) = at_mouse_button1press(d::DrawArea, event)

function at_mouse_motion(d::DrawArea, event)
    h = height(d.canvas)
    w = width(d.canvas)
    if d.can_draw && 0 < event.x < w && 0 < event.y < h
        redraw(d)
        # draw extra line
        ctx = getgc(d.canvas)
        set_dash(ctx, [10.,10.,10.])
        move_to(ctx, d.coords[end,1], d.coords[end,2])
        line_to(ctx, event.x, event.y)
        stroke(ctx)
        reveal(d.canvas)
    end
end

function at_mouse_button3press_wheel(d::DrawArea, event)
    if d.can_draw
        d.coords = vcat(d.coords,[d.coords[1,1] d.coords[1,2]]) # append first point to make closed wheel
        npoints = 2000
        crd_interp = interp1(d.coords,npoints) # interpolate in npoints
        crd_interp = crd_interp[!isnan(crd_interp)]
        n = length(crd_interp)/2
        d.coords = vcat((d.coords[1,:])',reshape(crd_interp,(convert(Int64,n),2))) # nan safety
        redraw(d)
        reveal(d.canvas)
        d.can_draw = false # disable drawing
    end
end

# interpolate coords in npoints
function interp1(coords,npoints)
    x = coords[:,1]
    y = coords[:,2]
    dcoords = diff(coords)
    n = length(x)
    dx = zeros(size(x))
    dx[1] = 0.
    for i in 2:n
        dx[i] = norm(dcoords[i-1])
    end
    dx = cumsum(dx)
    itp_x = interpolate((dx,), x, Gridded(Linear()))
    x_new = itp_x[linspace(dx[1],dx[end],npoints)]
    itp_y = interpolate((dx,), y, Gridded(Linear()))
    y_new = itp_y[linspace(dx[1],dx[end],npoints)]
    hcat(x_new,y_new)
end

# smooth data using moving average assuming the data represents a connected line
filter_connected(data,period) = begin
    n = length(data)
    data = data[vcat(n-period:n,1:n)]
    [mean(data[max(1, i-period):i]) for i in period+1:period+n]
end