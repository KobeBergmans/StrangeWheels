function plotwheel(t::Number,Θ::Vector,x::Vector,y::Vector,revs::Integer)
  # Input: time t which is between 0 and 99
  # Θ is a vector of angles
  # x is a vector of axle positions
  # y is a vector of road heights
  # revs = number of times the plot should be repeated

  # compute the index k of the vectors Θ,x,y corresponding to time t
  # compute the position x0 of the wheel at time t
  revlen = div(100,revs)
  revno, currev = divrem(t,revlen)
  k = 1000*div(revlen,currev)
  x0 = x[end]*revno + x[k]

  # Level of axle
  plot([0,revs*x[end]],[0,0],color=:black,linestyle=:dash)
  # Road
  for n = 0:revs-1
    plot!(x+n*x[end],y,linewidth=3,xlims=(0,x[end]),ylims=(-5,5),legend=false,color=:blue)
  end
  # axle
  plot!(x0+.05cos(Θ),.05sin(Θ),color=:black,linewidth=3)
  # wheel at time t
  plot!(x0-y.*sin(Θ+Θ[k]),rads.*sin(Θ+Θ[k]),color=:black,linewidth=3)
end
