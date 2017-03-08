
function wheel2road(r=Θ -> 1 + .25*abs(sin(3*Θ)),h=0.0005)
  # Input:
  # Function of wheel in polar coordinates, step-size h
  # Output:
  # Θ: vector of 2*pi*h-equispaced angles, Θ[1] = -pi/2
  # x: vector of positions the wheel has turned to at corresponding Θ[k]
  # y: vector of heights of the road at the time defined by Θ[k]

  # M is max radius, so perimeter is 2piM
  M = maximum(r(linspace(-pi/2,3*pi/2,1000)))

  # For evenly spaced angles Θ, compute the position of the wheel axle
  Θ = -pi/2           # Wheel begins in this orientation
  x = 0                   # Wheel begins at the left most point
  while x[end] < 3pi*M    # Until the wheel turns about 1.5 times
    Θ = [Θ; restrict(Θ[end] + 2pi*h,-pi/2,3pi/2)]
    x = [x;x[end]+r(Θ[end])*2pi*h]
  end

  # The height of the road in terms of the angle the wheel has rotated
  y = -r(Θ)
  Θ,x,y
end

function plotwheel(t,Θ,x,y,r)
  # Input: time t which is between 1 and 100

  k = t*div(length(x),100)
  angles = linspace(-pi/2,3*pi/2,1000)
  angles = [angles;angles[1]]  # Ensures the wheel is a closed curve
  rads = r(angles)
  M = maximum(rads)
  angles = angles - pi/2 - Θ[k]

  # Road
  plot(x,y,linewidth=3,xlims=(0,3pi*M),ylims=(-3M,3M),legend=false)
  # Level of axle
  plot!([0,3pi*M],[0,0],color=:black,linestyle=:dash)
  # axle
  plot!(x[k]+M*.05*cos(angles),M*.05*sin(angles),color=:black,linewidth=3)
  # wheel at time t_k
  plot!(x[k]+rads.*cos(angles),rads.*sin(angles),color=:black,linewidth=3)
end

# function wheel2interact(r,h=0.0005)
#
#   Θ,x,y = wheel2road(r,h)
#
#   # Produce the points traced out by the wheel for all times
#   n = length(x)
#   angles = linspace(-pi/2,3*pi/2,1000)
#   angles = [angles;angles[1]]  # Ensures the wheel is a closed curve
#   anglemesh = ones(n)*angles' - (pi/2 + Θ)*ones(1001)'
#   radiusmesh = ones(n)*r(angles)'
#   wheelx = x*ones(1001)' + radiusmesh.*cos(anglemesh)
#   wheely = radiusmesh.*sin(anglemesh)
#
#   M = maximum(r(angles))
#
#   # Preallocate number of frames
#   nframes = 100;
#   step = floor(n/nframes);
#
#   @manipulate for k = 1:step:n
#     plot(x,y,linewidth=3,xlims=(0,3pi*M),ylims=(-2M,2M),legend=false)   # Road
#     plot!([0,3pi*M],[0,0],color=:black,linestyle=:dot)    # Level of axle
#     plot!(x[k]+M*.05*cos(angles),M*.05*sin(angles),color=:black,linewidth=3) # axle
#     plot!(wheelx[k,:],wheely[k,:],color=:black,linewidth=3) # wheel at time t_k
#   end
# end
