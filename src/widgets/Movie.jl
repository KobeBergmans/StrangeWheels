#
# MOVIE
# Main file to make a Wheels movie from existing png's

using Gtk.ShortNames, Graphics, Cairo, Interpolations

# frame defintion
type Frames{n}
    frames
    k
end

Frames(frames) = Frames{length(frames)}(frames,-1)

next{n}(frames::Frames{n}) = begin
    frames.k = mod(frames.k+1,n-1)
    return frames.frames[frames.k+1]
end

# canvas functions
function update(canvas, frames::Frames)
    draw(canvas)
end

function init(canvas, frames::Frames)
  return Timer(timer -> update(canvas, frames), 0, 0.03)
end

function draw_frame(canvas, frames::Frames)
  ctx = getgc(canvas)
  h = height(canvas)
  w = width(canvas)
  set_source_surface(ctx, next(frames), 0, 0)
  paint(ctx)
  reveal(canvas)
end

# movie
type Movie{n}
    window
    canvas
    frames
    condition
end

function Movie(n)
    window = Gtk.GtkWindow("wheel animation",n,n)
    canvas = Gtk.GtkCanvas(n,n)
    stop_btn = Gtk.GtkButton("done")
    layout = Gtk.GtkBox(:v)
    layouth = Gtk.GtkBox(:h)
    n = sum(map(x->x[1:5],readdir("images")).=="frame")
    frames = Frames([read_from_png("images/frame_$(i).png") for i = 1:n])
    condition = Condition()

    push!(window, layout)
    push!(layout, canvas)
    push!(layout, stop_btn)

    setproperty!(window,:resizable,false)

    movie = Movie{n}(window, canvas, frames, condition)

    signal_connect((x)->notify(condition), window, "destroy")
    signal_connect((x)->notify(condition), stop_btn, "clicked")

    showall(movie.window)

    return movie
end

function play(movie::Movie)
    timer = init(movie.canvas, movie.frames)
    draw(canvas -> draw_frame(canvas, movie.frames), movie.canvas)
    wait(movie.condition)
    close(timer)
end

# I don't manage to call another toplevel window from an existing toplevel window
# and to make it play the movie. HACK: I will call this file from termial using run(`...`)
m = Movie(400)
play(m)



































