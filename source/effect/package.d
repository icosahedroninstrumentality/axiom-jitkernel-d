module effect;

public import effect.blur;
public import effect.copy;
public import effect.glass;
public import effect.glass_stroke;
public import effect.gradient;
public import effect.shape;
public import effect.stroke;
public import framework;

public void initEffects () {
	initStroke();
	initGlassStroke();
	initShape();
}
