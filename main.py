import moderngl_window as mglw

class App(mglw.WindowConfig):
    window_size = (1600, 900)
    gl_version = (3, 3)
    resource_dir = 'shaders'
    title = 'i3float'
    fullscreen = False

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.quad = mglw.geometry.quad_fs()
        self.program = self.load_program(vertex_shader='vertex.glsl', fragment_shader='fragment.glsl')
        self.program['u_resolution'].value = self.window_size
        self.program['u_performance_mode'].value = False

    def render(self, time, frames):
        self.ctx.clear()
        self.quad.render(self.program)
    
    def mouse_position_event(self, x, y, dx, dy):
        self.program['u_mouse'].value = (x, y)

if __name__ == '__main__':
    mglw.run_window_config(App)
