#
# GUI_UTILS
# Utilities for Wheels GUI

# scaling functions to map to canvas 
function canvas2polar(w,h,x,y)
    x_s = x-w/2
    y_s = h/2-y
    r = sqrt(x_s.^2+y_s.^2)
    r = r/maximum(r) # inside unit circle
    θ = restrict(atan2(y_s,x_s),-π/2,3*π/2)
    return θ,r
end

function road2canvas(x,y,w,h)
    # maps from (-1,1) -> (w,h)
    x = x*h/2
    y = h/2*(1-y)
    return x,y
end

# helper functions
restrict(t,a,b) = a + mod(t-a,b-a)

function is_valid_wheel(θ)
    # HEURISTIC!
    # detect number of sign changes in scnd derivative of θ
    d = diff(min(0.02,diff(θ)))
    d[find(d.<1e-10)] = 0.
    s = sign_changes(d)
    is_valid = s < 100
    return is_valid
end

sign_changes(s) = length(find(diff(sign(s)+1).!=0))

function rotate(r,θ)
    θ = restrict(θ,-π/2,3π/2)
    idx = sortperm(θ)
    return r[idx], θ[idx]
end
