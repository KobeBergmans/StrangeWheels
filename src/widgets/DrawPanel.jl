#
# DRAW PANEL
# A draw panel consist of buttons to control the gui

# widget defintion
type DrawPanel
    compute
    load
    smooth
    clear
    check
    animate
    help
    close
end

# outer constructor for DrawPanel
# n     size of the window
DrawPanel() = DrawPanel(
    Gtk.GtkButton("compute"),
    Gtk.GtkButton("load"),
    Gtk.GtkButton("smooth"),
    Gtk.GtkButton("clear"),
    Gtk.GtkToggleButton("check"),
    Gtk.GtkButton("animate"),
    Gtk.GtkButton("help"),
    Gtk.GtkButton("exit")
)

function at_clear_btn_clicked(gui::GUI)
    gui.draw_area.coords = zeros(Float64,0,2)
    gui.draw_area.can_draw = false
    gui.draw_area.first_click = true
    gui.drag_area.θ = Float64[]
    gui.drag_area.x = Float64[]
    gui.drag_area.y = Float64[]
    gui.drag_area.k = 1
    redraw(gui.drag_area)
    reveal(gui.drag_area.canvas)
    redraw(gui.draw_area)
    reveal(gui.draw_area.canvas)
    stop_playing!(gui.movie)
end

function at_compute_btn_clicked(gui::GUI)
    if !gui.draw_area.can_draw && !isempty(gui.draw_area.coords) # fool proof check
        w = width(gui.draw_area.canvas)
        h = height(gui.draw_area.canvas)
        # compute road
        wheelx = gui.draw_area.coords[:,1]
        wheely = gui.draw_area.coords[:,2]
        θ,r = canvas2polar(w,h,wheelx,wheely)
        r,θ = rotate(r,θ)
        if is_valid_wheel(θ)
            x,y = data_road2wheel(θ,r)
            set(gui.drag_area,θ,x,y)
            draw_road(gui)
            draw_wheel(gui)
        else
            throw_invalid_wheel_warning(gui,"Your wheel is invalid!","try again")
        end
    end
end

function at_smooth_btn_clicked(gui::GUI)
    if !gui.draw_area.can_draw
        if !isempty(gui.draw_area.coords) # fool proof check
            filter_smoothness = 10
            x = gui.draw_area.coords[:,1]
            xf = filter_connected(x,filter_smoothness)
            y = gui.draw_area.coords[:,2]
            yf = filter_connected(y,filter_smoothness)
            gui.draw_area.coords = hcat(append!(xf,xf[1]),append!(yf,yf[1]))
            redraw(gui.draw_area)
            reveal(gui.draw_area.canvas)
        end
        if !isempty(gui.drag_area.θ) # also smoothen road when already computed
            gui.drag_area.k = 1
            gui.drag_area.rev = 0
            at_compute_btn_clicked(gui)
        end
    end
end

function at_load_btn_clicked(gui::GUI)
    at_clear_btn_clicked(gui)
    w = width(gui.draw_area.canvas)
    h = height(gui.draw_area.canvas)
    θ, radius = choose_wheel(gui.toggle_panel)
    x = radius.*cos(θ)*w/2*0.95+w/2
    y = radius.*sin(θ)*h/2*0.95+h/2
    gui.draw_area.coords = hcat(x,h-y)
    redraw(gui.draw_area)
    reveal(gui.draw_area.canvas)
    gui.draw_area.first_click = false
end

function at_check_btn_clicked(gui::GUI)
    gui.drag_area.check = getproperty(gui.draw_panel.check, :active, Bool)
end

function throw_invalid_wheel_warning(gui::GUI,message1,message2)
    help_window = Gtk.GtkMessageDialog(message1, ((message2, 0), ),
                   Gtk.GtkDialogFlags.DESTROY_WITH_PARENT, Gtk.GtkMessageType.QUESTION, gui.window)

    setproperty!(help_window,:window_position,Gtk.GtkWindowPosition.GTK_WIN_POS_CENTER_ON_PARENT)
    setproperty!(help_window,:use_markup,true)

    response = run(help_window)
    destroy(help_window)
    response == 1

    at_clear_btn_clicked(gui)
end

function at_help_btn_clicked(gui::GUI)
     message = "
     <b>Drawing a wheel</b>

     Start drawing a wheel by left-clicking in the drawing area.
     Left click or click and drag to shape your wheel. 
     Right click to finish the wheel.

     <b>Sliding the wheel</b>

     Once a wheel is drawn, click and drag on the road to see how
     the wheel rolls.

     <b>Animating</b>

     When a wheel is computed, make a short animation of a
     car using your custom wheel!

     <b>Controls</b>

     Press 'compute' to use the current drawing as a wheel.
     Press 'load' to load a standard wheel.
     Press 'smooth' to smoothen your wheel.
     Press 'clear' to erase your drawing.
     Toggle the 'check' button to check if the wheel shows cusps.
     Press 'help' to open this dialog.
     "

    help_window = Gtk.GtkMessageDialog(message, (("got it!", 0), ),
                   Gtk.GtkDialogFlags.DESTROY_WITH_PARENT, Gtk.GtkMessageType.QUESTION, gui.window)

    setproperty!(help_window,:window_position,Gtk.GtkWindowPosition.GTK_WIN_POS_CENTER_ON_PARENT)
    setproperty!(help_window,:use_markup,true)
    setproperty!(help_window,:resizable,false)

    response = run(help_window)
    destroy(help_window)
    response == 1
end

function at_animate_btn_clicked{n}(gui::GUI{n})
    if !gui.draw_area.can_draw && !isempty(gui.drag_area.θ) # fool proof check
        compute_animation(gui)
        reload(gui.movie)
        play(gui.movie)
    end
end

function compute_animation{n}(gui::GUI{n})
    # pick 100 equidistant points in range
    start = gui.drag_area.x[1]
    stop = gui.drag_area.x[end]
    points = linspace(start, stop, 100)
    for i in 1:length(points)
        # get k value (index in x) closest to that point -> constant speed of the road
        k = min(length(gui.drag_area.x),searchsortedfirst(gui.drag_area.x,points[i]))
        # compute movie frame
        get_frame(gui,k,i)
    end
end

function get_frame{n}(gui::GUI{n}, k, teller) # plots wheel at orientation k and saves to png

    c = CairoRGBSurface(n,n)
    ctx = CairoContext(c)

    # background
    save(ctx)
    car = read_from_png("car_images/$(get_car(gui.car_panel)).png")
    scale(ctx,n/400,n/400)
    set_source_surface(ctx, car, 0, 0)
    paint(ctx)

    restore(ctx)
    save(ctx)

    d = gui.drag_area

    # interpolate θ, x, y evenly in 0:2π
    #tt = linspace(-π/2,3π/2,length(d.θ))
    #itp_x = interpolate((d.θ,), d.x, Gridded(Linear()))
    #itp_y = interpolate((d.θ,), d.y, Gridded(Linear()))
    #xx = itp_x[tt]
    #yy = itp_y[tt]
    xx = d.x
    yy = d.y
    tt = d.θ

    # road
    rx,ry = road2canvas(xx,yy,n/4,n/4)
    t = tt
    rx_ = rx
    ry_ = ry
    while rx[1]+rx_[k] > 0
        rx = vcat(rx_-rx[end],rx)
        ry = vcat(ry,ry_)
    end
    while rx[end]+rx_[k] < n
        rx = vcat(rx,rx[end]+rx_)
        ry = vcat(ry,ry_)
    end
    set_line_width(ctx,3)
    set_source_rgb(ctx, 0, 0, 1)
    m = length(xx)
    for i in 2:length(rx)
        move_to(ctx, rx[i]+rx_[k], 2*n/4 + ry[i])
        line_to(ctx, rx[i-1]+rx_[k], 2*n/4 + ry[i-1])
    end
    stroke(ctx)

    # wheel A
    m = mod(searchsortedfirst(rx+rx_[k],n/4),length(xx))+1
    wx,wy = road2canvas(yy.*sin(tt-tt[m]),yy.*cos(tt-tt[m]),n/4,n/4)
    set_source_rgb(ctx, 0, 0, 0)
    set_line_width(ctx,2)
    move_to(ctx, n/4 - wx[1], n/2 + wy[1])
    for i = 2:length(yy)
        line_to(ctx, n/4 - wx[i-1], n/2 + wy[i-1])
        #move_to(ctx, n/4 - wx[i], n/2 + wy[i])
        #line_to(ctx, n/4, 5*n/8) # fill wheel
    end
    close_path(ctx)
    stroke_preserve(ctx)
    fill(ctx)

    # wheel B
    m = mod(searchsortedfirst(rx+rx_[k],3*n/4),length(xx))+1
    wx,wy = road2canvas(yy.*sin(tt-tt[m]),yy.*cos(tt-tt[m]),n/4,n/4)
    set_source_rgb(ctx, 0, 0, 0)
    move_to(ctx, 3*n/4 - wx[1], n/2 + wy[1])
    for i = 2:length(yy)
        line_to(ctx, 3*n/4 - wx[i-1], n/2 + wy[i-1])
        #move_to(ctx, 3*n/4 - wx[i], n/2 + wy[i])
        #line_to(ctx, 3*n/4, 5*n/8) # fill wheel
    end
    close_path(ctx)
    stroke_preserve(ctx)
    fill(ctx)

    # axle A
    set_source_rgb(ctx, 1, 1, 1)
    arc(ctx, n/4, 5*n/8, n/100, 0, 2π)
    fill(ctx)

    # axle B
    set_source_rgb(ctx, 1, 1, 1)
    arc(ctx, 3*n/4, 5*n/8, n/100, 0, 2π)
    fill(ctx)

    restore(ctx)
    save(ctx)
    write_to_png(c,"images/frame_$(teller).png")
end