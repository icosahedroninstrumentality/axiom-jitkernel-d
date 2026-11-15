module jitkernel.texture;

import jitkernel.opengl;
import jitkernel.vector;
import bindbc.opengl;
import std.string;

public GLuint fb;

public class Texture {
	public __gshared Texture raw = null;
	public __gshared Texture screen;
	public __gshared Texture temp;

	public __gshared bool floatRenderable;
	public __gshared GLuint internalFormat;
	public __gshared GLuint pixelType;

	public Vector4 rect;
	public Vector2 size;
	public GLuint id;

	this (Vector2 size_) {
		size = size_;
		rect = Vector4(Radian.zero, Radian.zero, size.x, size.y);
		id = 0;
	}

	public void allocate () {
		if (id != 0) return;
		glGenTextures(1, &id);
		glBindTexture(GL_TEXTURE_2D, id);
		glTexImage2D(
			GL_TEXTURE_2D, 0, internalFormat,
			cast (GLsizei) size.x.raw,
			cast (GLsizei) size.y.raw,
			0, GL_RGBA, pixelType, null
		);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
	}

	~this () {
		if (id != 0) {
			glDeleteTextures(1, &id);
			id = 0;
		}
	}

	public void use () {
		if (id == 0) allocate();
		glBindFramebuffer(GL_FRAMEBUFFER, fb);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, id, 0);
	}
	
	public void fill (Vector4 color) {
		use();
		glDisable(GL_SCISSOR_TEST);
		glViewport(0, 0, cast (GLsizei) size.x.raw, cast (GLsizei) size.y.raw);
		glClearColor(
			cast (GLclampf) color.x.raw,
			cast (GLclampf) color.y.raw,
			cast (GLclampf) color.z.raw,
			cast (GLclampf) color.w.raw,
		);
		glClear(GL_COLOR_BUFFER_BIT);
	}

	public void clear () {
		fill(Vector4(Radian.zero, Radian.zero, Radian.zero, Radian.one));
	}
	
	public static void clearRaw (Vector4 color = Vector4(Radian.zero, Radian.zero, Radian.zero, Radian.one)) {
		glDisable(GL_SCISSOR_TEST);
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glViewport(0, 0, cast (GLsizei) Texture.screen.size.x.raw, cast (GLsizei) Texture.screen.size.y.raw);
		glClearColor(
			cast (GLclampf) color.x.raw,
			cast (GLclampf) color.y.raw,
			cast (GLclampf) color.z.raw,
			cast (GLclampf) color.w.raw,
		);
		glClear(GL_COLOR_BUFFER_BIT);
		//glDrawArrays(GL_TRIANGLES, 0, 6);
	}
}
