	#version 100
	 attribute vec2 aPos;
	 attribute vec4 aColor;

	 varying vec4 outColor;
	
	void main() 
	{
		gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);
		outColor = aColor;
	}
