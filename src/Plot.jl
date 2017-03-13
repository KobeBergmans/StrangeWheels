function plotwheel(t,Θ,x,y,revs = 2)
  # Input: time t which is between 0 and 99
  # Θ is a vector of angles
  # x is a vector of axle positions
  # y is a vector of road heights
  # revs = number of revolutions of the wheel the road takes

  # compute the index k of the vectors Θ,x,y corresponding to time t
  # compute the position x0 of the wheel at time t
  revlen = div(100,revs)
  revno, currev = divrem(t,revlen)
  k = div(1000*currev,revlen)+1
  x0 = x[end]*revno + x[k]

  # Level of axle
  plot([0,revs*x[end]],[0,0],color=:black,linestyle=:dash,aspect_ratio=1,xlims=(0,revs*x[end]),ylims=(-5,5))

  # Road
  for n = 0:revs-1
    plot!(x+n*x[end],y,legend=false,color=:blue,linewidth=3)
  end

  # axle
  plot!(x0+.05cos(Θ),.05sin(Θ),color=:black,linewidth=3)

  # wheel at time t
  plot!(x0-y.*sin(Θ-Θ[k]),y.*cos(Θ-Θ[k]),color=:black,linewidth=3)
end
