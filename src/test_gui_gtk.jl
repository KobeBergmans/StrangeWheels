using Gtk.ShortNames, Graphics, Cairo, Interpolations

NPOINTS = 1000
WINDOW_SIZE = 600
FILTER_SMOOTHNESS = 5

function action_when_wheel_was_drawn(r, θ)

    M = maximum(r)
    L = 2*π*M

    # interpolator over r
    itp_r = interpolate((θ,), r, Gridded(Linear()))

    theta = Vector{Float64}()
    temp_theta = -π/2
    append!(theta,temp_theta) # wheel begins in this orientation
    x = Vector{Float64}()
    temp_x = 0.
    append!(x,temp_x) # wheel begins at the left most point
    h = 1/NPOINTS/2 # step size in integration
    while temp_x < L
        temp_theta = restrict(temp_theta + 2*π*h,-π/2,3*π/2)
        append!(theta, temp_theta)
        temp_x += itp_r[temp_theta]*2*π*h
        append!(x,temp_x)
    end
    changes = find(abs(diff(sign(theta))) .> eps())
    x = x[1:changes[2]]
    y = -itp_r[theta[1:changes[2]]]

    return x, y
end

restrict(t,a,b) = a + mod(t-a,b-a)

function action_when_road_was_drawn(x, y)

    M = maximum(-y)
    L = 2*π*M

    # interpolation over y
    itp_y = interpolate((x,), y, Gridded(Linear()))

    theta = Vector{Float64}()
    temp_theta = -π/2
    append!(theta,temp_theta) # wheel begins in this orientation
    x = Vector{Float64}()
    temp_x = 0.
    append!(x,temp_x) # wheel begins at the left most point
    h = 1/NPOINTS/2 # step size in integration
    while temp_x < L
        temp_x = temp_x + h
        append!(x,temp_x)
        temp_theta = restrict(itp_y[temp_x],-π/2,3*π/2)
        append!(theta, temp_theta)
    end
    r = -itp_y[x]

    println(r)
    println(theta)

    return r, theta
end

# scaling functions to map from and to canvas 
function canvas_to_polar(w,h,x,y)
    x_s = x-w/2
    y_s = h/2-y
    r = sqrt(x_s.^2+y_s.^2)
    r = r/maximum(r) # inside unit circle
    θ = restrict(atan2(y_s,x_s),-π/2,3*π/2)
    return r,θ
end

function polar_to_canvas(θ,r,w,h)
    m = 0.9*min(w,h) # inside rectangle
    x = m*r.*cos(θ)+w/2
    y = m*r.*sin(θ)+h/2
    return x,y
end

function canvas_to_cartesian(w,h,x,y)
    x = x
    y = -y/h
    return x,y
end

function cartesian_to_canvas(x,y,w,h)
    x *= w/x[end]
    y *= -h
    return x,y
end

function rotate(r,θ)
    θ = restrict(θ,-π/2,3π/2)
    idx = sortperm(θ)
    println("start angle is $(θ[idx[1]])")
    return r[idx], θ[idx]
end

# holds data for a free drawing area
type MyFreeDrawContainer
    coords::Array{Float64,2} # can be Int64, but Float64 is easier for Interpolations.jl
    can_draw::Bool
    first_click::Bool
end

function reset(e::MyFreeDrawContainer)
    e.coords = zeros(Float64,0,2)
    e.can_draw = false
    e.first_click = true
end

# smooth data using moving average
filter(data,period) = [mean(data[max(1, i-period):i]) for i in 1:length(data)]

# smooth data using moving average assuming the data represents a connected line
filter_connected(data,period) = begin
    n = length(data)
    data = data[vcat(n-period:n,1:n)]
    [mean(data[max(1, i-period):i]) for i in period+1:period+n]
end

int(x::Float64) = convert(Int64,round(x))

# interpolate in NPOINTS
function interp1(coords)
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
    x_new = itp_x[linspace(dx[1],dx[end],NPOINTS)]
    itp_y = interpolate((dx,), y, Gridded(Linear()))
    y_new = itp_y[linspace(dx[1],dx[end],NPOINTS)]
    hcat(x_new,y_new)
end

function start_gui()
    #
    # DEFINE WIDGETS
    #

    # variables
    wheelFreeDrawContainer = MyFreeDrawContainer(zeros(Float64,0,2),false,true)
    roadFreeDrawContainer = MyFreeDrawContainer(zeros(Float64,0,2),false,true)
    c = Condition() # c will be notified when exit was pushed

    # all widgets
    window = @Window("test",WINDOW_SIZE,int(1.3375*WINDOW_SIZE))
    vbox = @Box(:v) # vertical layout
    setproperty!(vbox, :spacing, int(0.025*WINDOW_SIZE))
    hbox_wheel = @Box(:h) # horizontal layout
    hbox_road = @Box(:h) # horizontal layout
    canvas_wheel = @Canvas(int(0.875*WINDOW_SIZE),int(0.875*WINDOW_SIZE))
    canvas_road = @Canvas(int(0.875*WINDOW_SIZE),int(0.4375*WINDOW_SIZE))
    btn_compute_wheel = @Button("compute")
    btn_load_wheel = @Button("load")
    btn_clear_wheel = @Button("clear")
    btn_smooth_wheel = @Button("smooth")
    rbtn_wheel_1 = @RadioButton("flower")
    rbtn_wheel_2 = @RadioButton("corn")
    rbtn_wheel_3 = @RadioButton("pacman")
    rbtn_wheel_4 = @RadioButton("peanut")
    rbtn_wheel_5 = @RadioButton("square")
    rbtn_wheel_6 = @RadioButton("cardioid")
    rbtn_wheel_7 = @RadioButton("shell")
    btn_compute_road = @Button("compute")
    btn_load_road = @Button("load")
    btn_clear_road = @Button("clear")
    btn_smooth_road = @Button("smooth")
    rbtn_road_1 = @RadioButton("sine")
    rbtn_road_2 = @RadioButton("triangle")
    rbtn_road_3 = @RadioButton("saw")
    grid_wheel = @Grid(margin=int(0.0125*WINDOW_SIZE))
    grp_wheel = @RadioButtonGroup()
    grid_road = @Grid(margin=int(0.0125*WINDOW_SIZE))
    grp_road = @RadioButtonGroup()

    # connectivity
    push!(window, vbox)
    push!(vbox, hbox_wheel)
    push!(hbox_wheel, canvas_wheel)
    push!(hbox_wheel, grid_wheel)
    grid_wheel[1,1] = btn_compute_wheel
    grid_wheel[1,2] = btn_load_wheel
    grid_wheel[1,3] = btn_clear_wheel
    grid_wheel[1,4] = btn_smooth_wheel
    push!(hbox_wheel, grp_wheel)
    push!(grp_wheel,rbtn_wheel_1)
    push!(grp_wheel,rbtn_wheel_2)
    push!(grp_wheel,rbtn_wheel_3)
    push!(grp_wheel,rbtn_wheel_4)
    push!(grp_wheel,rbtn_wheel_5)
    push!(grp_wheel,rbtn_wheel_6)
    push!(grp_wheel,rbtn_wheel_7)
    push!(vbox, hbox_road)
    push!(hbox_road, canvas_road)
    push!(hbox_road, grid_road)
    grid_road[1,1] = btn_compute_road
    grid_road[1,2] = btn_load_road
    grid_road[1,3] = btn_clear_road
    grid_road[1,4] = btn_smooth_road
    push!(hbox_road, grp_road)
    push!(grp_road,rbtn_road_1)
    push!(grp_road,rbtn_road_2)
    push!(grp_road,rbtn_road_3)

    # CSS
    # style_file = joinpath(dirname(Base.source_path()), "mystylesheet.css")

    # screen   = Gtk.GAccessor.screen(window)
    # provider = CssProviderLeaf(filename=style_file)

    # ccall((:gtk_style_context_add_provider_for_screen, Gtk.libgtk), Void,
    #       (Ptr{Void}, Ptr{GObject}, Cuint),
    #       screen, provider, 1)

    # # adjust grid properties
    # setproperty!(grid_wheel,:row_spacing,int(0.025*WINDOW_SIZE))
    # setproperty!(grid_road,:row_spacing,int(0.025*WINDOW_SIZE))
    # setproperty!(vbox,:spacing,int(0.025*WINDOW_SIZE))

    #
    # BUTTON HANDLING
    #

    # notify c when window gets destroyed
    signal_connect(window, :destroy) do widget
        notify(c)
    end

    ## WHEEL ##

    # COMPUTE = a wheelFreeDrawContainer was drawn
    signal_connect(btn_compute_wheel, "clicked") do widget
        if !isempty(wheelFreeDrawContainer.coords)
            w = width(canvas_wheel)
            h = height(canvas_wheel)
            x = wheelFreeDrawContainer.coords[:,1]
            y = wheelFreeDrawContainer.coords[:,2]
            r,θ = canvas_to_polar(w,h,x,y)
            r,θ = rotate(r,θ)
            x, y = action_when_wheel_was_drawn(r,θ)
            w = width(canvas_road)
            h = height(canvas_road)
            x, y = cartesian_to_canvas(x,y,w,h)
            reset(roadFreeDrawContainer)
            draw(canvas_road)
            roadFreeDrawContainer.coords = hcat(x,y)
            ctx = getgc(canvas_road)
            refresh(ctx, roadFreeDrawContainer)
            stroke(ctx)
            reveal(canvas_road)
            roadFreeDrawContainer.first_click = false
        end
    end

    # LOAD = load standard wheel from file
    signal_connect(btn_load_wheel, "clicked") do widget
        w = width(canvas_wheel)
        h = height(canvas_wheel)
        θ = collect(linspace(-π/2,3*π/2,NPOINTS))
        r(θ) = begin
            if getproperty(rbtn_wheel_1,:active,Bool)
                2/3*(1 + .25*abs(sin(3*θ)))
            elseif getproperty(rbtn_wheel_2,:active,Bool)
                0.8*1/π*(1 + .25*(θ-π/2).^2)
            elseif getproperty(rbtn_wheel_3,:active,Bool)
                0.5*max(1 + sign(θ),0.05)
            elseif getproperty(rbtn_wheel_4,:active,Bool)
                0.75*(1 + .5*sin(2*(θ)))
            elseif getproperty(rbtn_wheel_5,:active,Bool)
                1./(abs(cos(θ))+abs(sin(θ)))
            elseif getproperty(rbtn_wheel_6,:active,Bool)
                0.5*(1+ sin(θ-π/2))
            elseif getproperty(rbtn_wheel_7,:active,Bool)
                1/6*(1 + abs(θ))
            end #if
        end #begin
        radius = r(θ)
        if getproperty(rbtn_wheel_3,:active,Bool) # rotate when Pacman
            θ = θ + π/4 # rotate
        end
        if getproperty(rbtn_wheel_3,:active,Bool) || getproperty(rbtn_wheel_7,:active,Bool) # connect pacman and shell
            append!(θ,θ[1]) # connect
            append!(radius,radius[1])
        end
        x = radius.*cos(θ)*w/2*0.95+w/2
        y = radius.*sin(θ)*h/2*0.95+h/2
        reset(wheelFreeDrawContainer)
        draw(canvas_wheel)
        wheelFreeDrawContainer.coords = hcat(x,h-y)
        ctx = getgc(canvas_wheel)
        refresh(ctx, wheelFreeDrawContainer)
        stroke(ctx)
        reveal(canvas_wheel)
        wheelFreeDrawContainer.first_click = false
    end

    # CLEAR = clear wheelFreeDrawContainer canvas
    signal_connect(btn_clear_wheel, "clicked") do widget
        reset(wheelFreeDrawContainer)
        draw(canvas_wheel)
    end

    # SMOOTH = wheel smoother was clicked
    signal_connect(btn_smooth_wheel, "clicked") do widget
        x = wheelFreeDrawContainer.coords[:,1]
        xf = filter_connected(x,FILTER_SMOOTHNESS)
        y = wheelFreeDrawContainer.coords[:,2]
        yf = filter_connected(y,FILTER_SMOOTHNESS)
        reset(wheelFreeDrawContainer)
        draw(canvas_wheel)
        wheelFreeDrawContainer.coords = hcat(append!(xf,xf[1]),append!(yf,yf[1]))
        ctx = getgc(canvas_wheel)
        refresh(ctx, wheelFreeDrawContainer)
        stroke(ctx)
        reveal(canvas_wheel)
        wheelFreeDrawContainer.first_click = false
    end

    ## ROAD ##

    # COMPUTE = a roadFreeDrawContainer was drawn
    signal_connect(btn_compute_road, "clicked") do widget
        if !isempty(roadFreeDrawContainer.coords)
            w = width(canvas_road)
            h = height(canvas_road)
            x = roadFreeDrawContainer.coords[:,1]
            y = roadFreeDrawContainer.coords[:,2]
            x_c, y_c = canvas_to_cartesian(w,h,x,y)
            r, θ = action_when_road_was_drawn(x_c,y_c)
            w = width(canvas_wheel)
            h = height(canvas_wheel)
            x, y = polar_to_canvas(r,θ,w,h)
            reset(wheelFreeDrawContainer)
            draw(canvas_wheel)
            wheelFreeDrawContainer.coords = hcat(x,y)
            ctx = getgc(canvas_wheel)
            refresh(ctx, wheelFreeDrawContainer)
            stroke(ctx)
            reveal(canvas_wheel)
            wheelFreeDrawContainer.first_click = false
        end
    end

    # LOAD = load standard road from file
    signal_connect(btn_load_road, "clicked") do widget
        w = width(canvas_road)
        h = height(canvas_road)
        x = collect(linspace(1/NPOINTS,1-1/NPOINTS,NPOINTS))
        road(x) = begin
            if getproperty(rbtn_road_1,:active,Bool)
                -sin(2*π*x)
            elseif getproperty(rbtn_road_2,:active,Bool)
                2*((2*(4*x-floor(4*x))-1).*sign(sin((2*pi*4*x))))+1
            elseif getproperty(rbtn_road_3,:active,Bool)
                2*(5*x-floor(5*x))-1
            end #if
        end #begin
        y = (-road(x)*h/2/3)+h/2
        x *= w
        reset(roadFreeDrawContainer)
        draw(canvas_road)
        roadFreeDrawContainer.coords = hcat(x,y)
        ctx = getgc(canvas_road)
        refresh(ctx, roadFreeDrawContainer)
        stroke(ctx)
        reveal(canvas_road)
        roadFreeDrawContainer.first_click = false
    end

    # CLEAR = clear roadFreeDrawContainer canvas
    signal_connect(btn_clear_road, "clicked") do widget
        reset(roadFreeDrawContainer)
        draw(canvas_road)
    end

    # SMOOTH = road smoother was clicked
    signal_connect(btn_smooth_road, "clicked") do widget
        x = roadFreeDrawContainer.coords[:,1]
        xf = filter(x,FILTER_SMOOTHNESS)
        y = roadFreeDrawContainer.coords[:,2]
        yf = filter(y,FILTER_SMOOTHNESS)
        reset(roadFreeDrawContainer)
        draw(canvas_road)
        roadFreeDrawContainer.coords = hcat(append!(xf,x[end-FILTER_SMOOTHNESS+1:end]),append!(yf,y[end-FILTER_SMOOTHNESS+1:end]))
        ctx = getgc(canvas_road)
        refresh(ctx, roadFreeDrawContainer)
        stroke(ctx)
        reveal(canvas_road)
        roadFreeDrawContainer.first_click = false
    end

    #
    # CANVAS HANDLING
    #

    @guarded draw(canvas_wheel) do widget
        w = width(widget)
        h = height(widget)
        ctx = getgc(widget)
        set_source_rgb(ctx, 1, 1, 1)
        paint(ctx)
        set_source_rgb(ctx, 0, 0, 0)
        arc(ctx, w/2, h/2, 0.025*WINDOW_SIZE, 0, 2pi)
        fill(ctx)
    end

    @guarded draw(canvas_road) do widget
        w = width(widget)
        h = height(widget)
        ctx = getgc(widget)
        set_source_rgb(ctx, 1, 1, 1)
        paint(ctx)
        set_source_rgb(ctx, 0, 0, 0)
        set_dash(ctx, [10.,10.,10.])
        move_to(ctx,0,0.5)
        line_to(ctx,w,0.5)
        stroke(ctx)
        set_dash(ctx, Vector{Float64}())
    end

    function refresh(ctx, e::MyFreeDrawContainer)
        set_dash(ctx, Vector{Float64}())
        set_source_rgb(ctx, 0, 0, 0)
        for i = 2:size(e.coords,1)
            move_to(ctx, e.coords[i,1], e.coords[i,2])
            line_to(ctx, e.coords[i-1,1], e.coords[i-1,2])
        end
    end

    function at_mouse_button1press(widget, event, e::MyFreeDrawContainer)
        if e.first_click
            e.can_draw = true
            e.first_click = false
        end
        if e.can_draw
            draw(widget)
            ctx = getgc(widget)
            e.coords = vcat(e.coords,[event.x event.y])
            refresh(ctx,e)
            stroke(ctx)
            reveal(widget)
        end
    end

    function at_mouse_button1motion(widget, event, e::MyFreeDrawContainer)
        if e.can_draw
            draw(widget)
            ctx = getgc(widget)
            refresh(ctx,e)
            stroke(ctx)
            reveal(widget)
            e.coords = vcat(e.coords,[event.x event.y])
        end
    end

    function at_mouse_motion(widget, event, e::MyFreeDrawContainer)
        if e.can_draw
            draw(widget)
            ctx = getgc(widget)
            refresh(ctx,e)
            stroke(ctx)
            set_dash(ctx, [10.,10.,10.])
            move_to(ctx, e.coords[end,1], e.coords[end,2])
            line_to(ctx, event.x, event.y)
            stroke(ctx)
            reveal(widget)
        end
    end

    function at_mouse_button3press_wheel(widget, event, e::MyFreeDrawContainer)
        if e.can_draw
            draw(widget)
            ctx = getgc(widget)
            e.coords = vcat(e.coords,[e.coords[1,1] e.coords[1,2]]) # append first point to make closed wheel
            crd_interp = interp1(e.coords)
            crd_interp = crd_interp[!isnan(crd_interp)]
            n = length(crd_interp)/2
            e.coords = vcat((e.coords[1,:])',reshape(crd_interp,(int(n),2))) # nan safety
            refresh(ctx,e)
            stroke(ctx)
            reveal(widget)
            e.can_draw = false
        end
    end

    function at_mouse_button3press_road(widget, event, e::MyFreeDrawContainer)
        if e.can_draw
            draw(widget)
            ctx = getgc(widget)
            crd = e.coords
            n = size(crd,1)
            crd = crd[1,1]>crd[2,1] ? flipdim(crd,1) : crd # reverse direction
            crd_interp = interp1(crd)
            crd_interp = crd_interp[!isnan(crd_interp)]
            n = length(crd_interp)/2
            e.coords = reshape(crd_interp,(int(n),2)) # nan safety
            refresh(ctx,e)
            stroke(ctx)
            reveal(widget)
            e.can_draw = false
        end
    end

    # bindings
    canvas_wheel.mouse.button1press = @guarded (widget, event) -> at_mouse_button1press(widget, event, wheelFreeDrawContainer)
    canvas_wheel.mouse.button1motion = @guarded (widget, event) -> at_mouse_button1motion(widget, event, wheelFreeDrawContainer)
    canvas_wheel.mouse.motion = @guarded (widget, event) -> at_mouse_motion(widget, event, wheelFreeDrawContainer)
    canvas_wheel.mouse.button3press = @guarded (widget, event) -> at_mouse_button3press_wheel(widget, event, wheelFreeDrawContainer)
    canvas_road.mouse.button1press = @guarded (widget, event) -> at_mouse_button1press(widget, event, roadFreeDrawContainer)
    canvas_road.mouse.button1motion = @guarded (widget, event) -> at_mouse_button1motion(widget, event, roadFreeDrawContainer)
    canvas_road.mouse.motion = @guarded (widget, event) -> at_mouse_motion(widget, event, roadFreeDrawContainer)
    canvas_road.mouse.button3press = @guarded (widget, event) -> at_mouse_button3press_road(widget, event, roadFreeDrawContainer)

    #
    # START GUI
    #
    showall(window)
    wait(c)
end

start_gui()