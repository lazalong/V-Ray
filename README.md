
# vray

Minimal V RayLib project using VScode, Gcc and Gdb

![Output for now](output.png)

Note that the image represents the output for the latest commit.  If you want to see how the code follows the Ray Tracing In One Weekend code then check the previous commit to see the changes.

## Inspirations

Inspirations:
- https://github.com/vlang/v/blob/master/examples/gg/mandelbrot.v 
- https://raytracing.github.io/books/RayTracingInOneWeekend.html
- https://github.com/shovon/raytracing-vlang/blob/main/main.v


## Known Issue

- The exec compiled with TCC prod will run from a console but not from Visual Code... The debug works. It seems it is due to adding IMaterial to the struct HitRecord ?!? Before adding this the TCC prod worked. 


That's all folks!
Happy coding!
