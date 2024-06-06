	#version 100
	precision mediump float;


	uniform sampler2D texture;
	uniform sampler2D paletteStore;

	varying vec2 texPos;
	varying vec2 palPos;

	void main() {
		vec2 pos = inputFilter(texPos.xy);
		vec4 color = texture2D(texture, pos);
		vec2 index = vec2(palPos.x + color.a, palPos.y);
		vec4 indexedColor = outputFilter(texture2D(paletteStore, index));
		gl_FragColor = indexedColor;
	}