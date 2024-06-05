/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.gl.textures;

import hauntologl.gl.errors;
import hauntologl.gl.traits;
import hauntologl.gl.shaders;
import hauntologl.gl.config;


private string genTextureEnum() {
	import std.conv;
	string retval = `enum Unit {`;

	foreach (GLenum i; 0..32) {
		retval ~= "\n	Texture" ~ to!string(i) ~ " = GL_TEXTURE" ~ to!string(i) ~ ",";
	}

	return retval ~ "\n}";
}

class Texture {
	public:
	enum Type:GLenum {
		Texture2D = GL_TEXTURE_2D,
		TextureCubeMap = GL_TEXTURE_CUBE_MAP,
		TextureCubeMapPositiveX = GL_TEXTURE_CUBE_MAP_POSITIVE_X,
		TextureCubeMapNegativeX = GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
		TextureCubeMapPositiveY = GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
		TextureCubeMapNegativeY = GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
		TextureCubeMapPositiveZ = GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
		TextureCubeMapNegativeZ = GL_TEXTURE_CUBE_MAP_NEGATIVE_Z
	}
	enum Format:GLenum {
		Alpha = GL_ALPHA,
		Luminance = GL_LUMINANCE,
		LuminanceAlpha = GL_LUMINANCE_ALPHA,
		RGB = GL_RGB,
		RGBA = GL_RGBA
	}
	enum Size:GLenum {
		UByte = GL_UNSIGNED_BYTE,
		UShort565 = GL_UNSIGNED_SHORT_5_6_5,
		UShort4444 = GL_UNSIGNED_SHORT_4_4_4_4,
		UShort5551 = GL_UNSIGNED_SHORT_5_5_5_1
	}
	enum Parameter:GLenum {
		MinFilter = GL_TEXTURE_MIN_FILTER,
		MagFilter = GL_TEXTURE_MAG_FILTER,
		WrapS = GL_TEXTURE_WRAP_S,
		WrapT = GL_TEXTURE_WRAP_T
	}
	enum Filter:GLenum {
		Nearest = GL_NEAREST,
		Linear = GL_LINEAR,
		NearestMipmapNearest = GL_NEAREST_MIPMAP_NEAREST,
		LinearMipmapNearest = GL_LINEAR_MIPMAP_NEAREST,
		NearestMipmapLinear = GL_NEAREST_MIPMAP_LINEAR,
		LinearMipmapLinear = GL_LINEAR_MIPMAP_LINEAR
	}

	static size_t pixelSize(Format format, Size size) {
		final switch (size) {
			case Size.UShort4444:
			case Size.UShort5551:
			case Size.UShort565:
				return 2;
			case Size.UByte:
				final switch (format) {
					case Format.Alpha:
					case Format.Luminance:
						return 1;
					case Format.LuminanceAlpha:
						return 2;
					case Format.RGB:
						return 3;
					case Format.RGBA:
						return 4;
				}
		}
	}

	mixin(genTextureEnum());

	static void setActiveUnit(Unit newunit) {
		glActiveTexture(newunit);
		version (GLDebug) checkError();
	}

	this() {
		glGenTextures(1, &handle_);
		version (GLDebug) checkError();
	}

	~this() {
		glDeleteTextures(1, &handle_);
		version (GLDebug) checkError();
	}

	void update(const(void)[] data, GLsizei width, GLsizei height, GLenum format = Format.RGBA, GLenum pixelSize = Size.UByte, Type target = Type.Texture2D, GLint level = 0, GLenum internalFormat = Format.RGBA, GLint border = 0) {
		this.bind(target);

		glTexImage2D(target, level, internalFormat, width, height, border, format, pixelSize, data.ptr);
		version (GLDebug) checkError();
	}

	void updateSub(const(void)[] data, GLsizei xOffset, GLsizei yOffset, GLsizei width, GLsizei height, GLenum format = Format.RGBA, GLenum pixelSize = Size.UByte, Type target = Type.Texture2D, GLint level = 0) {
		this.bind(target);

		glTexSubImage2D(target, level, xOffset, yOffset, width, height, format, pixelSize, data.ptr);
		version (GLDebug) checkError();
	}

	void setParameter(T)(GLenum parameter, T value, Type target = Type.Texture2D) if (is(T:int) || is(T:float)) {
		bind(target);
		static if (is(T:int)) {
			glTexParameteri(target, parameter, value);
		} else static if (is(T:float)) {
			glTexParameterf(target, parameter, value);
		} else static assert(0);

	}

	T getParameter(T)(GLenum parameter, Type target = Type.Texture2D) if (is(T == int) || is(T == float)) {
		bind(target);
		static if (is(T == int)) {
			int retval;
			glGetTexParameteriv (target, parameter, &retval);
			version (GLDebug) checkError();
			return retval;
		} else static if (is(T == float)) {
			float retval;
			version (GLDebug) checkError();
			glGetTexParameterfv (target, parameter, &retval);
			return retval;
		} else static assert(0);
	}

	void generateMipmap(Type target) {
		this.bind();
		glGenerateMipmap(target);
	}

	package:
	GLuint handle_;

}

void bind(const(Texture) texture, Texture.Type target = Texture.Type.Texture2D)  {
	glBindTexture(target, texture?texture.handle_:0);
}

void setUniform(const(ShaderProgram) s, GLuint position, const(Texture) tex) {
	ShaderProgram.setUniform(position, tex.handle_);
}

void setUniform(const(ShaderProgram) s, const(char)[] name, const(Texture) tex) {
	assert (s);
	s.setUniform(name, tex.handle_);
}