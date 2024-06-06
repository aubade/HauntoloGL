module hauntologl.render;

import hauntologl.drawable;
import hauntologl.window;
import hauntologl.gl.textures;

@disable class RenderWindow:Window,DrawTarget {
	void bindTarget() {

	}

	this(T...)(auto ref T params) {
		super (params);
	}
}

class RenderTexture:Texture,DrawTarget {
	void bindTarget() {

	}
}