function road2wheel(y = x->-1,h=0.0005)
  # Input:
  # Road as a function y(x), step-size h
  # Output:
  # x : vector of h-equispaced points
  # Θ: vector of 2*π*h-equispaced angles, Θ[1] = -π/2
  # x: vector of positions the wheel has turned to at corresponding Θ[k]
  # y: vector of heights of the road at the time defined by Θ[k]

  # M is max radius, so perimeter is 2πM
  M = maximum(r(linspace(-π/2,3*π/2,1000)))

  x = 0
  Θ = -π/2
  while Θ < 3π
    x = [x;x[end]+h]
    Θ = 5
  end



  # For evenly spaced angles Θ, compute the position of the wheel axle
  Θ = -π/2           # Wheel begins in this orientation
  x = 0                   # Wheel begins at the left most point
  while x[end] < 3π*M    # Until the wheel turns about 1.5 times
    Θ = [Θ; restrict(Θ[end] + 2π*h,-π/2,3π/2)]
    x = [x;x[end]+r(Θ[end])*2π*h]
  end

  # The height of the road in terms of the angle the wheel has rotated
  y = -r(Θ)
  Θ,x,y
end
