#
# CAR PANEL
# A car panel consist of buttons to toggle the predefined car

# widget defintion
type CarPanel
    family_car
    race_car
    fire_truck
    tractor
    bulldozer
    school_bus
    police_car
    truck
end

# outer constructor for CarPanel
# n     size of the window
CarPanel() = CarPanel(
    Gtk.GtkRadioButton("family car"),
    Gtk.GtkRadioButton("race car"),
    Gtk.GtkRadioButton("fire truck"),
    Gtk.GtkRadioButton("tractor"),
    Gtk.GtkRadioButton("bulldozer"),
    Gtk.GtkRadioButton("school bus"),
    Gtk.GtkRadioButton("police car"),
    Gtk.GtkRadioButton("truck")
)

function get_car(c::CarPanel)
    car_name = begin
        if getproperty(c.family_car,:active,Bool)
            "family_car"
        elseif getproperty(c.race_car,:active,Bool)
            "race_car"
        elseif getproperty(c.fire_truck,:active,Bool)
            "fire_truck"
        elseif getproperty(c.tractor,:active,Bool)
            "tractor"
        elseif getproperty(c.bulldozer,:active,Bool)
            "bulldozer"            
        elseif getproperty(c.school_bus,:active,Bool)
            "school_bus"
        elseif getproperty(c.police_car,:active,Bool)
            "police_car"
        elseif getproperty(c.truck,:active,Bool)
            "truck"
        end
    end
end

