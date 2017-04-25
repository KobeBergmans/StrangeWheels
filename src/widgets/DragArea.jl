#
# DRAG AREA
# A drag area is where the wheel can be dragged

# widget definition
type DragArea{n}
    canvas
    θ
    x
    y
    k
    rev
    check
end

# outer constructor for DragArea
# n     size of the window
DragArea(n::Int64) = begin
	# construct Gtk canvas
	canvas = @Canvas(n,n/2)

	# construct draw area
	drag_area = DragArea{n}(canvas,Float64[],Float64[],Float64[],1,0,false)
    @guarded draw(canvas) do widget
        redraw(drag_area) # to ensure that canvas is drawn on startup
    end

    # attach actions
    canvas.mouse.button1motion = @guarded (widget, event) -> at_mouse_button1motion(drag_area, event)

	return drag_area
end

# setter
function set(d::DragArea,θ,x,y)
    d.θ = θ
    d.x = x
    d.y = y
end

# redraw canvas
function redraw(d::DragArea)
    # get height and width of canvas
    h = height(d.canvas)-SCREEN_F
    w = width(d.canvas)
    # get Cairo context
    ctx = getgc(d.canvas)
    # draw canvas
    set_source_rgb(ctx, 1, 1, 1)
    rectangle(ctx, 0, 0, w, h+SCREEN_F)
    fill(ctx)
    # border
    set_dash(ctx, Vector{Float64}())
    set_line_width(ctx, 3)
    set_source_rgb(ctx, 0, 0, 0)
    rectangle(ctx, 0, 0, w, h+SCREEN_F)
    stroke(ctx)
    # draw axle level
    set_line_width(ctx, 2)
    set_source_rgb(ctx, 0, 0, 0)
    set_dash(ctx, [10.,10.,10.])
    move_to(ctx,0,(h+SCREEN_F)/2)
    line_to(ctx,w,(h+SCREEN_F)/2)
    stroke(ctx)
    reveal(d.canvas)
end

# implementation of all actions
function at_mouse_button1motion(d::DragArea, event)
    w = width(d.canvas)
    if !isempty(d.θ) && (0 < event.x) && (event.x < w)
        h = height(d.canvas)-SCREEN_F
        rev = convert(Int64,ceil(event.x/(d.x[end]*h/2)))-1
        k = searchsortedfirst(d.x,2*event.x/h-rev*d.x[end])
        redraw(d)
        draw_road(d)
        d.k = k
        d.rev = rev
        draw_wheel(d)
    end
end

draw_road(gui::GUI) = draw_road(gui.drag_area)

function draw_road(d::DragArea)
    h = height(d.canvas)-SCREEN_F
    w = width(d.canvas)
    rx,ry = road2canvas(d.x,d.y,w,h)
    rx_ = rx
    ry_ = ry
    while rx[end] < w
        rx = vcat(rx,rx[end]+rx_)
        ry = vcat(ry,ry_)
    end

    ctx = getgc(d.canvas)
    redraw(d)
    set_dash(ctx, Vector{Float64}())
    set_source_rgb(ctx, 0, 0, 1)
    for i in 2:length(rx)
        move_to(ctx, rx[i], ry[i] + SCREEN_F/2)
        line_to(ctx, rx[i-1], ry[i-1] + SCREEN_F/2)
    end
    stroke(ctx)
    reveal(d.canvas)
end

draw_wheel(gui::GUI) = draw_wheel(gui.drag_area)

function draw_wheel(d::DragArea)
    k = d.k
    rev= d.rev
    x0 = d.x[k]
    h = height(d.canvas)-SCREEN_F
    w = width(d.canvas)
    rx,ry = road2canvas(x0-d.y.*sin(d.θ-d.θ[k]),d.y.*cos(d.θ-d.θ[k]),w,h)
    
    ctx = getgc(d.canvas)
    d.check && wheel_has_cusp(d.x,d.y,rx,ry,k,h) ? set_source_rgb(ctx, 1, 0, 0) : set_source_rgb(ctx, 0, 0, 0)

    # draw axle
    arc(ctx, (rev*d.x[end]+x0)*h/2, (h + SCREEN_F)/2, h/50, 0, 2pi)
    fill(ctx)

    # draw wheel
    for i = 2:length(d.y)
        move_to(ctx, rev*d.x[end]*h/2+rx[i], ry[i] + SCREEN_F/2)
        line_to(ctx, rev*d.x[end]*h/2+rx[i-1], ry[i-1] + SCREEN_F/2)
    end
    move_to(ctx, rev*d.x[end]*h/2+rx[1], ry[1] + SCREEN_F/2) # extra assert closed wheel for "smooth shell"
    line_to(ctx, rev*d.x[end]*h/2+rx[length(d.y)], ry[length(d.y)] + SCREEN_F/2)
    stroke(ctx)
    reveal(d.canvas)
end

function wheel_has_cusp(x,y,rx,ry,k,h)
    valid_wheel = true
    i = 1
    while valid_wheel && i <= length(rx)
        idx = searchsortedfirst(x*h/2,restrict(rx[i],x[1]*h/2,x[end]*h/2))
        if idx < length(x)
            valid_wheel = h/2*(1-y[idx]) >= ry[i]-1.5
        end
        i += 1
    end
    return !valid_wheel
end

const SCREEN_F = 20 # fix: distance from road to border of canvas
