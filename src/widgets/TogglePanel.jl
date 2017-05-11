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
    shell
    star
    gear
    pentagram
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
    Gtk.GtkRadioButton("shell"),
    Gtk.GtkRadioButton("star"),
    Gtk.GtkRadioButton("gear"),
    Gtk.GtkRadioButton("polygon")
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
            N = getproperty(gui.slider,:value,Int64)
            sc = N == 3 ? 0.5 : 0.75
            -sc*csc(restrict(θ,-π/2-π/N,-π/2+π/N))
        elseif getproperty(t.shell,:active,Bool)
            1/6*(1 + abs(θ))
        elseif getproperty(t.star,:active,Bool)
            s = 1.0
            v = 0.3
            n = 5
            0.75*abs(exp(1im*θ).*(s + v*sin(n*θ + π/2)))
        elseif getproperty(t.gear,:active,Bool)
            nteeth = 10
            0.03*involute_r.( θ * nteeth * 200 / (2.0 * π) )
        end
    end
    radius = r(θ)
    if getproperty(t.shell,:active,Bool) # connect shell
        append!(θ,θ[1])
        append!(radius,radius[1])
    end
    return θ, radius
end

function involute_r(angle)
    #angle is given in teeth-hundredths
    inner = 11.0
    outer = 12.0
    bottom_width = 22.0
    top_width = 5.0
    angle = mod(angle,100.0)
    if angle > 50.0
        # symmetry
        angle = 100.0 - angle
    end
    if angle < bottom_width
        return inner
    end
    if angle > (50 - top_width)
        return outer
    end
    halfway = (inner + outer) / 2.0
    transition_width = 50 - top_width - bottom_width
    curve = 1.0 - (angle - (50 - top_width))^2 / (transition_width^2)
    return   halfway +  curve * (outer - halfway)
end