#
# MOVIE
# Main file to make a Wheels movie from existing png's

using Gtk.ShortNames, Graphics, Cairo, Interpolations

import Base:next,reload

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
    canvas
    frames
    timer # nothing if not playing, Timer if we are
end

function Movie(n)
    canvas = Gtk.GtkCanvas(n,n)
    n = sum(map(x->x[1:5],readdir("images")).=="frame")
    frames = Frames([read_from_png("images/frame_$(i).png") for i = 1:n])

    movie = Movie{n}(canvas, frames, nothing)

    return movie
end

function reload(movie::Movie)
    n = sum(map(x->x[1:5],readdir("images")).=="frame")
    movie.frames = Frames([read_from_png("images/frame_$(i).png") for i = 1:n])
end

function stop_playing!(movie::Movie)
    if movie.timer != nothing
        close(movie.timer)
        movie.timer = nothing
        # clear canvas
        ctx = getgc(movie.canvas)
        h = height(movie.canvas)
        w = width(movie.canvas)
        set_source_rgb(ctx, 1, 1, 1)
        rectangle(ctx, 0, 0, w, h)
        fill(ctx)
        reveal(movie.canvas)
    end
end

function stept(movie::Movie)
    next(movie.frames)
end

function play(movie::Movie)
    stop_playing!(movie)
    dt = 0.03
    movie.timer = Timer(timer -> draw_frame(movie.canvas, movie.frames), dt, dt)
end
