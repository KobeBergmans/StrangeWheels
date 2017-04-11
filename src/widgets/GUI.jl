#
# GUI
# Main file to construct a Wheels GUI

type GUI{n}
    window
    draw_area
    draw_panel
    drag_area
    toggle_panel
    car_panel
    condition
end

GUI(n::Int64=400) = begin

    # create all GUI fields
    window = Gtk.GtkWindow("Wheels",2*n,n)
    draw_area = DrawArea(n)
    draw_panel = DrawPanel()
    drag_area = DragArea(n)
    toggle_panel = TogglePanel()
    car_panel = CarPanel()
    condition = Condition()

    # create GUI type
    gui = GUI{n}(window, draw_area, draw_panel, drag_area, toggle_panel, car_panel, condition)

    # layout widgets
    vbox = Gtk.GtkBox(:v)
    hbox = Gtk.GtkBox(:h)
    panel = Gtk.GtkButtonBox(:v)
    radioframe = Gtk.GtkFrame("Choose wheel")
    radiogroup = @RadioButtonGroup()
    radioframe2 = Gtk.GtkFrame("Choose car")
    radiogroup2 = @RadioButtonGroup()

    # set properties
    setproperty!(window,:name,"MyWindow")
    setproperty!(window,:resizable,false)
    setproperty!(window,:window_position,Gtk.GtkWindowPosition.GTK_WIN_POS_CENTER_ALWAYS)
    setproperty!(window,:modal,true)
    setproperty!(vbox,:spacing,12)
    setproperty!(vbox,:name,"MyVBox")
    setproperty!(panel,:name,"MyPanel")
    setproperty!(hbox,:spacing,12)
    setproperty!(draw_panel.compute,:name,"compute")
    setproperty!(radiogroup,:margin,6)
    setproperty!(radiogroup,:spacing,6)
    setproperty!(radioframe,:expand,true)
    setproperty!(radiogroup2,:margin,6)
    setproperty!(radiogroup2,:spacing,6)
    setproperty!(radioframe2,:expand,true)

    # interconnections
    push!(hbox, draw_area.canvas)
    for btn_symbol in fieldnames(draw_panel) # push all draw panel buttons
        btn = getfield(draw_panel,btn_symbol)
        if typeof(btn) == Gtk.GtkButtonLeaf || typeof(btn) == Gtk.GtkToggleButtonLeaf
            push!(panel,btn)
        end
    end
    push!(hbox, panel)
    push!(vbox, hbox)
    push!(vbox, drag_area.canvas)
    push!(window,vbox)
    for btn_symbol in fieldnames(toggle_panel) # push all toggle panel buttons
        btn = getfield(toggle_panel,btn_symbol)
        if typeof(btn) == Gtk.GtkRadioButtonLeaf
            push!(radiogroup,btn)
        end
    end
    push!(radioframe,radiogroup)
    push!(hbox,radioframe)
    for btn_symbol in fieldnames(car_panel) # push all car panel buttons
        btn = getfield(car_panel,btn_symbol)
        if typeof(btn) == Gtk.GtkRadioButtonLeaf
            push!(radiogroup2,btn)
        end
    end
    push!(radioframe2,radiogroup2)
    push!(hbox,radioframe2)

    # actions
    signal_connect((x)->at_clear_btn_clicked(gui), draw_panel.clear, "clicked")
    signal_connect((x)->at_compute_btn_clicked(gui), draw_panel.compute, "clicked")
    signal_connect((x)->at_smooth_btn_clicked(gui), draw_panel.smooth, "clicked")
    signal_connect((x)->at_load_btn_clicked(gui), draw_panel.load, "clicked")
    signal_connect((x)->at_check_btn_clicked(gui), draw_panel.check, "clicked")
    signal_connect((x)->at_animate_btn_clicked(gui), draw_panel.animate, "clicked")
    signal_connect((x)->at_help_btn_clicked(gui), draw_panel.help, "clicked")
    signal_connect((x)->notify(gui.condition), window, "destroy")

    # CSS
    style_file = joinpath(dirname(Base.source_path()), "css_no_color.css")

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
