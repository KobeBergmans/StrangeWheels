
# The two functions below use Euler's method to solve the relevant ODE
# Since the road and wheel in general have no differentiability, there
# is no real benefit to using better ODE solvers

function equi_wheel2road(r = Θ->1+.25abs(sin(3Θ)))
  # Input: Function of wheel in polar coordinates
  # Output: 1 revolution of the wheel on road
  # Θ: linspace of 1000 equispaced angles, Θ[1] = -π/2, Θ[1000] = 3π/2
  # x: vector of 1000 positions of the wheel axle
  # y: vector of 1000 heights of the road

  Θ = linspace(-π/2,3π/2,1000)
  dΘ = 0.002π
  x = cumsum(r(Θ)dΘ)          # Euler's method for x'(Θ) = r(Θ)
  y = -r(Θ)

  if abs(y[end]-y[1]) > dΘ
    println("Warning: this  wheel is not closed.")
    y[end] = y[1]
  end

  Θ,x,y
end

function equi_road2wheel(f = x->1)
  # Input: Function for road, f(x)
  # Output: 1 revolution of the wheel on road
  # Θ: linspace of 1000 equispaced angles, Θ[1] = -π/2, Θ[1000] = 3π/2
  # x: vector of 1000 positions of the wheel axle
  # y: vector of 1000 heights of the road

  Θ = linspace(-π/2,3π/2,1000)
  dΘ = 0.002π
  x = zeros(1000)
  for k = 2:1000
    x[k] = x[k-1] - f(x[k-1])*dΘ   # Euler's method for x'(Θ) = -f(x(Θ))
  end
  y = f(x)

  if abs(y[end]-y[1]) > dΘ
    println("Warning: this road gave a wheel that is not closed.")
    y[end] = y[1]
  end

  Θ,x,y
end

function data_road2wheel(Θ,r)
  # Input: data points Θ (angles) and r (radius of wheel at that angle)
  # Output: data points x (x-position of axle) and y (y-position of road)

  # Euler's method for x'(Θ) = r(Θ), x(Θ[1]) = 0
  x = [0;cumsum(r[1:end-1].*diff(Θ))]

  y = -r(Θ)

  x,y
end

function data_wheel2road(x,y)
  # Input: data points x and y for the road
  # Output: data points Θ and r for the wheel

  # Euler's method for Θ'(x) = = -1/y(x), Θ(x[1]) = -π/2
  Θ = -π/2 + [0;cumsum(-diff(x)./y[1:end-1])]

  r = -y

  Θ,r
end
