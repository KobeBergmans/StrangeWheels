
function wheel2road(r = Θ->1+.25abs(sin(3Θ)))
  # Input: Function of wheel in polar coordinates
  # Output: 1 revolution of the wheel on road
  # Θ: linspace of 1000 equispaced angles, Θ[1] = -π/2
  # x: vector of 1000 positions of the wheel axle
  # y: vector of 1000 heights of the road

  Θ = linspace(-π/2,3π/2,1000)
  dΘ = 0.002π
  x = cumsum(r(Θ)dΘ)          # Euler's method for x'(Θ) = r(Θ)
  y = -r(Θ)
  y[end] = y[1]

  Θ,x,y
end

function road2wheel(f = x->1)
  # Input: Function for road, f(x)
  # Output: 1 revolution of the wheel on road
  # Θ: linspace of 1000 equispaced angles, Θ[1] = -π/2
  # x: vector of 1000 positions of the wheel axle
  # y: vector of 1000 heights of the road

  Θ = linspace(-π/2,3π/2,1000)
  dΘ = 0.002π
  x = zeros(1000)
  y = zeros(1000)
  for k = 2:1000
    y[k-1] = yofx(x[k-1])
    x[k] = x[k-1] - h*f(x[k-1])   # Euler's method for x'(Θ) = -f(x(Θ))
  end
  y[end] = y[1]

  Θ,x,y
end
