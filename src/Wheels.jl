import Plots, Interact

export restrict

export wheel2interact, wheel2road, plotwheel

include("helper.jl")
include("Wheel2Road.jl")
include("Road2Wheel.jl")


# Create a function for the wheel in polar coords
r1 = Θ -> 1 + .25*abs(sin(3*Θ));              # Flower
  r2 = Θ -> 1 + .25*(Θ-pi/2).^2;                # Acorn
  r3 = Θ -> max(1 + sign(Θ),0.05);              # Pacman
  r4 = Θ -> 1 + .5*sin(2*(Θ));             # Peanut
  r5 = Θ -> 1+ sin(Θ-pi/2);                     # Cardioid
  r6 = Θ -> 1./(abs(cos(Θ))+abs(sin(Θ)));   # Square
  N = 5                                       # N-sided polygon
  r7 = Θ -> -csc(restrict(Θ,-pi/2-pi/N,-pi/2+pi/N));
  r8 = Θ -> 1 + abs(Θ);                         # Crazy snail-shell
