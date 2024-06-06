/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */
	
module hauntologl.palette;
import hauntologl.gl.textures;
import hauntologl.gl.shaders;
import gl3n.linalg;

import std.bitmanip;
import std.algorithm;

alias Color = Vector!(ubyte, 4);

private immutable string palVertex = "
	uniform matrix4 transform;
	uniform 

";

private immutable string palFragment = "

";
class PaletteCollection {

	this (ushort capacity) {
		store_ = new Texture();
		store_.setParameter(Texture.Parameter.WrapT, Texture.Wrap.Repeat);
		store_.setParameter(Texture.Parameter.WrapS, Texture.Wrap.Repeat);
		store_.setParameter(Texture.Parameter.MagFilter, Texture.Filter.Nearest);
		store_.setParameter(Texture.Parameter.MinFilter, Texture.Filter.Nearest);
		store_.update(null, ubyte.max, capacity);
	}

	void update (in Palette child, const(Color)[] data) {
		store_.updateSub(data, child.offset_, child.index_, min(data.length, child.length_) * 4, 1);
	}

	void update (in Palette child, const(ubyte[4])[] data) {
		store_.updateSub(data, child.offset_, child.index_, min(data.length, child.length_) * 4, 1);
	}

	void update (in Palette child, const(ubyte)[] data) {
		store_.updateSub(data, child.offset_, child.index_, min(data.length, child.length_ * 4), 1);
	}

	private: 

	Palette[] children_;
	ushort lastused_;
	Texture store_;
	BitArray used;
}

struct Palette {

	void update(T) (const(T)[] data) {
		if (home_) home_.update(this, data);
	}

	void bind(ShaderProgram s) {
		if (s) setUniform( s, "paletteStore", home_?home_.store_:null);
	}

	private:
	ushort index_;
	ubyte offset_;
	ubyte length_;
	PaletteCollection home_;
}