
function wheel2road(r=Θ -> 1 + .25*abs(sin(3*Θ)),dΘ=0.002π)
  # Input:
  # Function of wheel in polar coordinates, step-size dΘ
  # Output:
  # Θ: vector of 1500  dΘ-equispaced angles, Θ[1] = -π/2, 1.5 turns
  # x: vector of 1500 positions of the wheel axle
  # y: vector of 1500 heights of the road

  Θ = linspace(-π/2,2.5π,1500)
  x = cumsum(r(Θ)*dΘ)
  y = -r(Θ)

  Θ,x,y
end

#function road2wheel(y = x->1)

function plotwheel(t,Θ,x,y,r)
  # Input: time t which is between 1 and 100

  # Grid has 1500 pts
  k = 15t

  # Angle spacing small for sharp edges and first = last + 2π
  angles = linspace(-π/2,1.5π,1000)
  rads = r(angles)
  M = maximum(rads)
  angles = angles - π/2 - Θ[k]

  # Road
  plot(x,y,linewidth=3,xlims=(0,3π*M),ylims=(-3M,3M),legend=false)
  # Level of axle
  plot!([0,3π*M],[0,0],color=:black,linestyle=:dash)
  # axle
  plot!(x[k]+M*.05cos(angles),M*.05sin(angles),color=:black,linewidth=3)
  # wheel at time t
  plot!(x[k]+rads.*cos(angles),rads.*sin(angles),color=:black,linewidth=3)
end
