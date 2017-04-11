#
# TOGGLE PANEL
# A toggle panel consist of buttons to toggle the predefined wheel

# widget defintion
type TogglePanel
    square
    flower
    corn
    pacman
    peanut
    cardioid
    pentagram
    shell
end

# outer constructor for TogglePanel
# n     size of the window
TogglePanel() = TogglePanel(
    Gtk.GtkRadioButton("square"),
    Gtk.GtkRadioButton("flower"),
    Gtk.GtkRadioButton("corn"),
    Gtk.GtkRadioButton("pacman"),
    Gtk.GtkRadioButton("peanut"),
    Gtk.GtkRadioButton("cardioid"),
    Gtk.GtkRadioButton("pentagram"),
    Gtk.GtkRadioButton("shell")
)

function choose_wheel(t::TogglePanel)
    θ = collect(linspace(-π/2,3*π/2,1000))
    r(θ) = begin
        if getproperty(t.square,:active,Bool)
            1./(abs(cos(θ))+abs(sin(θ)))
        elseif getproperty(t.flower,:active,Bool)
            2/3*(1 + .25*abs(sin(3*(θ))))
        elseif getproperty(t.corn,:active,Bool)
            0.8*1/π*(1 + .25*(θ-π/2).^2)
        elseif getproperty(t.pacman,:active,Bool)
            #0.5*max(1 + sign(θ-π/4),0.025)
            (2/pi*atan((θ-2*π/8)*100)-2/pi*atan((θ+2*π/8)*100))/2+1 # smoother version of pacman!
        elseif getproperty(t.peanut,:active,Bool)
            0.75*(1 + .5*sin(2*(θ)))            
        elseif getproperty(t.cardioid,:active,Bool)
            0.5*(1+ sin(θ-π/2))
        elseif getproperty(t.pentagram,:active,Bool)
            N = 5
            -0.75*csc(restrict(θ,-π/2-π/N,-π/2+π/N))
        elseif getproperty(t.shell,:active,Bool)
            1/6*(1 + abs(θ))
        end
    end
    radius = r(θ)
    if getproperty(t.shell,:active,Bool) # connect pacman and shell
        append!(θ,θ[1])
        append!(radius,radius[1])
    end
    return θ, radius
end