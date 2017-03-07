function theta = restrict(t,a,b)
  # Helper function gives the values of t mod (b-a) that lies between a and b.
  # Assume a < b ?
  theta = a + mod(t-a,b-a)
end
