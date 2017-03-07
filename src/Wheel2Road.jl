
# Create a function for the wheel in polar coords
# r = Θ -> 1 + .25*abs(sin(3*Θ));                % Flower
# r = Θ -> 1 + .25*(Θ-pi/2).^2;                % Acorn
# r = Θ -> max(1 + sign(Θ),0.05);              % Pacman
# r = Θ -> 1 + .5*sin(2*(Θ));             % Peanut
# r = Θ -> 1+ sin(Θ-pi/2);                     % Cardioid
# r = Θ -> 1./(abs(cos(Θ))+abs(sin(Θ)));   % Square
N = 5;                                                # N-sided polygon
 r = Θ -> -csc(restrict(Θ,-pi/2-pi/N,-pi/2+pi/N));
# r = Θ -> 1 + abs(Θ);                         % Crazy snail-shell


function wheel2road(r,h=0.0005)
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


function wheel2interact(r)

  Θ,x,y = wheel2road(r,h)

  # Produce the points traced out by the wheel for all times
  n = length(x)
  angles = linspace(-pi/2,3*pi/2,1000)
  angles = [angles,angles(1)]  # Ensures the wheel is a closed curve
  anglemesh = ones(n,1)*angles - (pi/2 + Θ)*ones(1,1001)
  radiusmesh = ones(n,1)*r(angles)
  wheelx = x*ones(1,1001) + radiusmesh.*cos(anglemesh)
  wheely = radiusmesh.*sin(anglemesh)

  M = maximum(r(angles))

  # Preallocate number of frames
  nframes = 100;
  step = floor(n/nframes);

  #@manipulate for k = 1:step:n
    plot(x,y,linewidth=3,xlims=(0,3pi*M),ylims=(-2M,2M))   # Road
    plot!([0,3pi*M],[0,0],color=:black,linestyle=:dot)    # Level of axle
    plot!(x[k]+M*.05*cos(angles),M*.05*sin(angles),color=:black,linewidth=3) # axle
    plot!(wheelx[k,:],wheely[k,:],color=:black,linewidth=3) # wheel at time t_k
  #end
end
