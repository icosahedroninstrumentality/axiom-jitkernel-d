module effect.shape;

import framework.jitkernel;
import framework.opengl;
import framework.texture;
import framework.vector;
import effect.copy;
import std.math;

public void drawShape (
	Surface surface,
	Texture source = Texture.screen,
	Texture target = Texture.screen
) {
	Vector4 region = Vector4(
		surface.shape.position.x - surface.shape.size.x,
		surface.shape.position.y - surface.shape.size.y,
		surface.shape.size.x * Radian.two,
		surface.shape.size.y * Radian.two,
	);

	if (back is null || back.size != Texture.screen.size) back = new Texture(Texture.screen.size);
	
	Copy.draw(region, source, region, back);

	uback.set(back);

	uposition.set(surface.shape.position);
	usize.set(surface.shape.size);
	//uradius.set(surface.shape.radius);
	upower.set((surface.shape.size * Radian.two) / surface.shape.radius);

	import std.algorithm;
	uminRadius.set(min(surface.shape.radius.x, surface.shape.radius.y));
	
	ualbedo.set(surface.albedo);
	uemission.set(surface.emission);

	uborder.set(surface.border.width);
	ubordercolor.set(surface.border.color);
	
	shader.draw(
		target,
		region,
	);
}

private Shader shader;

private Uniform!Vector2 uposition;
private Uniform!Vector2 usize;
private Uniform!Vector2 uradius;
private Uniform!Vector2 upower;
private Uniform!Radian uminRadius;

private Uniform!Vector4 ualbedo;
private Uniform!Vector4 uemission;
private Uniform!Vector4 ubordercolor;

private Uniform!Vector2 upx;
private Uniform!Radian uborder;

private Uniform!Texture uback;

private Texture back;

public void initShape () {
	shader = new Shader(`#version 330 core
	precision highp float;

	in vec2 uv;
	out vec4 finalColor;

	uniform vec2 position;
	uniform vec2 size;
	uniform vec2 radius;
	uniform float minRadius;
	uniform vec2 power;
	
	uniform vec4 albedo;
	uniform vec4 emission;
	uniform vec4 bordercolor;

	uniform float border;

	uniform sampler2D back;///min:l;mag:l;s:m;t:m;

	float calculateInside (vec2 Sposition) {
		vec2 d = pow(abs((Sposition - position) / size), power);
		return d.x + d.y;
	}

	float calculateMaskB (vec2 Sposition) {
		vec2 newPower = ((size - border) * 2.0) / (radius - border);
		vec2 d = pow(abs((Sposition - position) / (size - border)), newPower);
		return 1.0 - min(1.0, pow(d.x + d.y, (minRadius - border)));
	}

	void main() {
		vec4 refracted = vec4(0.0);
		vec4 reflected = vec4(0.0);

		float inside = calculateInside(gl_FragCoord.xy);
		if (inside > 1.0) { finalColor = texture(back, uv); return; }
		float mask = max(0.0, 1.0 - pow(inside, minRadius));

		vec4 bg = texture(back, uv);

		float bmask = calculateMaskB(gl_FragCoord.xy);
		finalColor = mix(
			bg,
			mix(
				mix(
					bg,
					vec4(bg.xyz*albedo.xyz+emission.xyz, 1),
					albedo.w
				),
				mix(
					bg,
					vec4(bordercolor.xyz, 1),
					bordercolor.w
				),
				border
			),
			mask
		);
	}
	`);

	uposition = shader.uniform!Vector2("position", Vector2.zero);
	usize = shader.uniform!Vector2("size", Vector2.zero);
	//uradius = shader.uniform!Vector2("radius", Vector2.zero);
	upower = shader.uniform!Vector2("power", Vector2.zero);
	uminRadius = shader.uniform!Radian("minRadius", Radian.zero);

	ualbedo = shader.uniform!Vector4("albedo", Vector4.one);
	uemission = shader.uniform!Vector4("emission", Vector4.one);
	ubordercolor = shader.uniform!Vector4("bordercolor", Vector4.one);

	uborder	= shader.uniform!Radian("border", Radian.zero);

	uback = shader.uniform!Texture("back", back);
}

public KernelStored!Radian calculateShape (
	Kernel k,
	KernelStored!Vector2 samplePoint,
	KernelStored!Vector2 position,
	KernelStored!Vector2 invSize,
	KernelStored!Vector2 power,
	KernelStored!Vector2 rotate,
) { with (k) {
	KernelStored!Vector2 offset = samplePoint - position;
	KernelStored!Vector2 rotated = compose(
		offset.component!"x" * rotate.component!"x" - offset.component!"y" * rotate.component!"y",
		offset.component!"x" * rotate.component!"y" + offset.component!"y" * rotate.component!"x",
	);
	KernelStored!Vector2 d = pow(abs(rotated * invSize), power);
	return d.component!"x" + d.component!"y";
}}

public KernelStored!Radian shapeMask (
	Kernel k,
	KernelStored!Radian inside,
	KernelStored!Radian corner,
) { with (k) {
	return pow(inside, corner);
}}

public struct Shape {
	Vector2 position;
	Vector2 size;
	Vector2 radius;
	Degree angle = 0;
}

/// bottom-left origin corner
public struct RectRound {
	Vector2 position;
	Vector2 size;
	Vector2 corner;
	Degree angle = 0;

	public Shape toShape () const {
		return Shape(
			position + size / Radian.two,
			size / Radian.two,
			corner,
			angle,
		);
	}

	alias toShape this;
}

public struct Border {
	Radian width;
	Vector4 color;
}

public struct Surface {
	Shape shape;
	Vector4 albedo;
	Vector4 emission;
	//Outline[] outlines;
	//Border[] borders;
	Border border;
}
