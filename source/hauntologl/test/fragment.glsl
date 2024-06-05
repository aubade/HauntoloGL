	#version 100
	precision mediump float;

	varying vec4 outColor; 

	void main() {
		gl_FragColor = outColor / 255.0;
	} 
