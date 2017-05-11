#
# GUI
# Main file to construct a Wheels GUI

type GUI{n}
    window
    draw_area
    draw_panel
    drag_area
    toggle_panel
    slider
    car_panel
    movie
    condition
    rfr
    rfr2
end

GUI() = begin

    # create window
    window = Gtk.GtkWindow("Wheels",10,10)

    # get screen size
    (screen_w,screen_h) = screen_size(window)
    padding = @static is_apple() ? 54 : 75
    n = convert(Int64,round(2*screen_h/3))-padding

    margin = convert(Int64,round(n/151))
    fontsize = convert(Int64,round(n/36))

    run(pipeline(`sed "s/font-size:.*$/font-size:$(fontsize)px;/g" css_no_color.css`,"css_no_color.css.tmp"))
    mv("css_no_color.css.tmp", "css_no_color.css",remove_destination=true)

    # create all other GUI fields
    draw_area = DrawArea(n)
    draw_panel = DrawPanel()
    drag_area = DragArea(n)
    toggle_panel = TogglePanel()
    slider = Gtk.GtkScale(false, 3:12)
    adj = Gtk.GtkAdjustment(slider)
    car_panel = CarPanel()
    movie = Movie(n)
    condition = Condition()

    # layout widgets
    tbox = Gtk.GtkBox(:h)    
    vbox = Gtk.GtkBox(:v)
    hbox = Gtk.GtkBox(:h)
    panel = Gtk.GtkBox(:v)
    sbox = Gtk.GtkBox(:v)
    radioframe = Gtk.GtkFrame("Choose wheel")
    rbox = Gtk.GtkBox(:v)
    radiogroup = @RadioButtonGroup()
    radioframe2 = Gtk.GtkFrame("Choose car")
    radiogroup2 = @RadioButtonGroup()

    # set properties
    setproperty!(window,:name,"MyWindow")
    setproperty!(window,:width_request,screen_w)
    setproperty!(window,:height_request,screen_h)
    setproperty!(window,:resizable,false)
    setproperty!(window,:window_position,Gtk.GtkWindowPosition.GTK_WIN_POS_CENTER_ALWAYS)
    setproperty!(window,:modal,true)
    setproperty!(vbox,:spacing,2*margin)
    setproperty!(panel,:name,"MyPanel")
    setproperty!(panel,:hexpand,true)
    setproperty!(panel,:spacing,2*margin)
    setproperty!(tbox,:hexpand,true)
    setproperty!(tbox,:name,"MyVBox")
    setproperty!(tbox,:spacing,2*margin)
    setproperty!(hbox,:spacing,2*margin)
    setproperty!(sbox,:spacing,2*margin)
    setproperty!(draw_panel.compute,:name,"compute")
    setproperty!(radiogroup,:margin,margin)
    setproperty!(radiogroup,:spacing,margin)
    setproperty!(radioframe,:hexpand,true)
    setproperty!(radiogroup2,:margin,margin)
    setproperty!(radiogroup2,:spacing,margin)
    setproperty!(radioframe2,:hexpand,true)
    setproperty!(draw_panel.close,:name,"ExitButton")
    setproperty!(draw_panel.compute,:name,"ComputeButton")
    setproperty!(adj,:value,5)

    # interconnections
    for btn_symbol in fieldnames(draw_panel) # push all draw panel buttons
        btn = getfield(draw_panel,btn_symbol)
        if typeof(btn) == Gtk.GtkButtonLeaf || typeof(btn) == Gtk.GtkToggleButtonLeaf
            push!(panel,btn)
        end
    end
    push!(tbox, panel)
    push!(tbox,vbox)
    push!(hbox, draw_area.canvas)
    push!(vbox, hbox)
    push!(vbox, drag_area.canvas)
    push!(window,tbox)
    for btn_symbol in fieldnames(toggle_panel) # push all toggle panel buttons
        btn = getfield(toggle_panel,btn_symbol)
        if typeof(btn) == Gtk.GtkRadioButtonLeaf
            push!(radiogroup,btn)
        end
    end
    push!(rbox,radiogroup)
    push!(rbox,slider)
    push!(radioframe,rbox)
    push!(sbox,radioframe)
    for btn_symbol in fieldnames(car_panel) # push all car panel buttons
        btn = getfield(car_panel,btn_symbol)
        if typeof(btn) == Gtk.GtkRadioButtonLeaf
            push!(radiogroup2,btn)
        end
    end
    push!(radioframe2,radiogroup2)
    push!(sbox,radioframe2)
    push!(hbox,sbox)
    push!(hbox,movie.canvas)

    # create GUI type
    gui = GUI{n}(window, draw_area, draw_panel, drag_area, toggle_panel, adj, car_panel, movie, condition, radioframe, radioframe2)


    # actions
    signal_connect((x)->at_clear_btn_clicked(gui), draw_panel.clear, "clicked")
    signal_connect((x)->at_compute_btn_clicked(gui), draw_panel.compute, "clicked")
    signal_connect((x)->at_smooth_btn_clicked(gui), draw_panel.smooth, "clicked")
    signal_connect((x)->at_load_btn_clicked(gui), draw_panel.load, "clicked")
    signal_connect((x)->at_check_btn_clicked(gui), draw_panel.check, "clicked")
    signal_connect((x)->at_animate_btn_clicked(gui), draw_panel.animate, "clicked")
    signal_connect((x)->at_help_btn_clicked(gui), draw_panel.help, "clicked")
    signal_connect((x)->at_language_btn_clicked(gui), draw_panel.language, "clicked")
    signal_connect((x)->notify(gui.condition), draw_panel.close, "clicked")
    signal_connect((x)->notify(gui.condition), window, "destroy")
    signal_connect(window, "key-press-event") do widget, event
        event.keyval == 65307 ? notify(gui.condition) : Void()
    end

    # CSS
    #filename = @static is_apple() ? "css_no_color.css" : "css_with_color.css"
    filename = "css_no_color.css"
    style_file = joinpath(dirname(Base.source_path()), filename)

    screen   = Gtk.GAccessor.screen(window)
    provider = CssProviderLeaf(filename=style_file)

    ccall((:gtk_style_context_add_provider_for_screen, Gtk.libgtk), Void,
        (Ptr{Void}, Ptr{GObject}, Cuint), screen, provider, 1.) 

    return gui
end

function display(gui::GUI)
    showall(gui.window)
    wait(gui.condition)
end
