module framework.ui;

import glfw3;
import std.string;
import std.conv;
import core.thread;
import framework;
import framework.opengl;
import bindbc.opengl;

@property bool supports (string[] extensions, string extension) @nogc @safe pure nothrow {
	return extensions.canFind(extension);
}

class Window {
	public string title = "New Window";
	public Vector4 rect = Vector4(Radian(0), Radian(0), Radian(0), Radian(0));
	public bool focused = false;

	public Element root;
	public Element[] content;

	private GLFWwindow* handle;
	public Thread manager;

	this (string _title = "New Window") {
		title = _title;
		manager = new Thread(() {
			if (!glfwInit()) {
				throw new Exception("Failed to initialize GLFW.");
			}

			glfwWindowHint(GLFW_RESIZABLE, false);
			handle = glfwCreateWindow(1024, 1024, title.toStringz, null, null);
			if (handle is null) {
				const(char)* description;
				int errorCode = glfwGetError(&description);
				glfwTerminate();
				throw new Exception(cast (string) ("GLFW Error "~to!string(errorCode)~": "~fromStringz(description)));
			}

			glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
			glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
			glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

			glfwMakeContextCurrent(handle);

			GLSupport gl = loadOpenGL();
			if (gl == GLSupport.noLibrary || gl == GLSupport.badLibrary) {
				glfwDestroyWindow(handle);
				glfwTerminate();
				throw new Exception("Failed to load OpenGL.");
			}

			string[] extensions = glGetString(GL_EXTENSIONS).to!string.split;

			Texture.floatRenderable = extensions.supports("GL_EXT_color_buffer_float");
			Texture.internalFormat = Texture.floatRenderable ? GL_RGBA16F : GL_RGBA8;
			Texture.pixelType = Texture.floatRenderable ? GL_HALF_FLOAT : GL_UNSIGNED_BYTE;


			root = new Element();

			glGenFramebuffers(1, &fb);
			import effect;
			initEffects();
			Glass g = new Glass();

			g.shape = Shape(
				Vector2(Radian.zero, Radian.zero),
				Vector2(Radian(128+64), Radian(64)),
				Vector2(Radian(64), Radian(64)),
				Degree.zero
			);

			double x,y;
			int ww,wh;

			glfwGetFramebufferSize(handle, &ww, &wh);
			Texture background = new Texture(Vector2(
				Radian(x),
				Radian(wh - y),
			));

			background.fill(Vector4.one);

			Texture.raw = null;
			if (Texture.screen is null || Texture.screen.size != Vector2(Radian(ww), Radian(wh))) Texture.screen = new Texture(Vector2(Radian(ww), Radian(wh)));
			if (Texture.temp is null || Texture.temp.size != Vector2(Radian(ww), Radian(wh))) Texture.temp = new Texture(Vector2(Radian(ww), Radian(wh)));

			while (!glfwWindowShouldClose(handle)) {
				glfwGetFramebufferSize(handle, &ww, &wh);
				glViewport(0, 0, ww, wh);
				
				Texture.screen.fill(Vector4.one);
				Texture.clearRaw();

				glfwGetCursorPos(handle, &x, &y);
				g.shape.position.x = Radian(x);
				g.shape.position.y = Radian(wh - y);
				g.shineAngle += Degree(1);

				int scale = 16;
				for (int by = 0; by < 1024; by += scale) {
					for (int bx = ((by / scale) % 2 == 1) ? 0 : scale; bx < 1024; bx += scale * 2) {
						Texture.screen.use();
						glEnable(GL_SCISSOR_TEST);
						glScissor(
							bx, by, scale, scale,
						);
						glClearColor(1.0, 0.0, 0.0, 1.0);
						glClear(GL_COLOR_BUFFER_BIT);
					}
				}

				g.draw();

				Copy.draw(
					Texture.screen.rect,
					Texture.screen,
					Texture.screen.rect,
					Texture.raw,
				);

				glfwSwapBuffers(handle);
				glfwPollEvents();
			}

			glfwDestroyWindow(handle);
			glfwTerminate();
		});
		manager.start();
	}

	VTexture refresh () {
		return root.refresh();
	}

	public Throwable waitForClose (bool rethrow = false) {
		return manager.join(rethrow);
	}

	unittest {
		import std.stdio;
		writeln("Making a new window");
		Window window = new Window("Test window");
	}
}

class Element {
	private VTexture vt;

	public Vector4 rect;
	
	public Element parent;
	public Element[] children;
	
	public VTexture delegate (Element) draw;
	
	Optional!VTexture refresh () {
		if (vt !is null) if (vt.cached) return vt;
		if (draw is null) return null;
		vt = draw(this);
		return vt;
	}
}

class Effect {
	this (VTexture delegate () drawCall) {}
}
