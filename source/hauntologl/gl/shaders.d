/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.gl.shaders;


import hauntologl.gl.config;
import hauntologl.gl.errors;
import hauntologl.gl.traits;

import std.meta;
import std.traits;


abstract class Shader {
	enum Type:GLenum {
		Vertex = GL_VERTEX_SHADER,
		Fragment = GL_FRAGMENT_SHADER
	}
	struct PrecisionFormat {
		GLint[2] range;
		GLint[2] precision;
	}

	static PrecisionFormat precisionFormat(GLenum shaderType, GLenum precisionType) @nogc  {
		switch (shaderType) {
			case Type.Vertex:
				return VertexShader.precisionFormat(precisionType);
			case Type.Fragment:
				return FragmentShader.precisionFormat(precisionType);
			default:
				return PrecisionFormat.init;
		}
	}

	void loadSource(const(char)[] source) @nogc const {
			GLint[1] lengths;
			const(char)*[1] strings;
			strings[0] = source.ptr;
			lengths[0] = cast(GLint)source.length;

			glShaderSource(getHandle, 1, strings.ptr, lengths.ptr);
			version (GLDebug) checkError();
	}

	void loadSource(const(char)[][] source)  {
		assert (source.length < GLint.max);
		GLint[] lengths;
		const(char)*[] strings;

		lengths.length = source.length;
		foreach (size_t i, ref S; source) {
			lengths[i] = cast(GLint) S.length;
			strings[i] = S.ptr;
		}
		glShaderSource(getHandle, cast(GLint)source.length, strings.ptr, lengths.ptr);
		version (GLDebug) checkError();
	}

	/*void loadSource(const(char)[][] source...) {
		loadSource(source);
	}*/

	auto getLog() const {
		import std.exception;
		char[] retval;
		GLint loglen;
		glGetShaderiv(getHandle, GL_INFO_LOG_LENGTH, &loglen);
		version (GLDebug) checkError();

		retval.length = loglen;
		GLint retlen;
		glGetShaderInfoLog(getHandle, loglen, &retlen, retval.ptr);
		version (GLDebug) checkError();

		return assumeUnique(retval);
	}

	void compile() const {
		GLint success;
		glCompileShader(getHandle);
		version (GLDebug) checkError();

		glGetShaderiv(getHandle, GL_COMPILE_STATUS, &success);
		version (GLDebug) checkError();

		if (!success) {
			throw new GLError(GLError.Code.CompilerError, "Error Compiling Shader");
		}

	}

	@property auto length() const @nogc {
		GLint retval;

		glGetShaderiv(getHandle, GL_SHADER_SOURCE_LENGTH, &retval);
		return retval;
	}
	@property GLenum compileStatus() const @nogc {
		GLint retval;

		glGetShaderiv(getHandle, GL_COMPILE_STATUS, &retval);

		return retval;
	}
	@property GLenum deleteStatus() const @nogc {
		GLint retval;

		glGetShaderiv(getHandle, GL_DELETE_STATUS, &retval);

		return retval;
	}


	@property GLenum type() const @nogc;
	protected @property GLuint getHandle() const @nogc;
}

class VertexShader:Shader {
	public:
	static auto precisionFormat(GLenum precisionType) @nogc  {
		Shader.PrecisionFormat retval;

		glGetShaderPrecisionFormat(GL_VERTEX_SHADER, precisionType, retval.range.ptr, retval.precision.ptr);

		return retval;
	}

	this() {
		handle_ = glCreateShader(GL_VERTEX_SHADER);
		version (GLDebug) glCheckError();
		assert(handle_);
	}

	this(const(char)[] source) {
		this();
		loadSource(source);
	}

	this(const(char)[][] source) {
		this();
		loadSource(source);
	}

	~this() {
		glDeleteShader(handle_);
	}

	override @property GLenum type() const @nogc {
		return Shader.Type.Vertex;
	}

	override protected @property GLuint getHandle() const @nogc {
		return handle_;
	}
	private:
	GLuint handle_;
}

class FragmentShader:Shader {
	public:
	static auto precisionFormat(GLenum precisionType) @nogc  {
		Shader.PrecisionFormat retval;

		glGetShaderPrecisionFormat(GL_FRAGMENT_SHADER, precisionType, retval.range.ptr, retval.precision.ptr);

		return retval;
	}

	this() {
		handle_ = glCreateShader(GL_FRAGMENT_SHADER);
		version (GLDebug) glCheckError();
		assert(handle_);
	}

	this(const(char)[] source) {
		this();
		loadSource(source);
	}

	this(const(char)[][] source) {
		this();
		loadSource(source);
	}

	~this() {
		glDeleteShader(handle_);
	}

	override @property GLenum type() const @nogc {
		return Shader.Type.Fragment;
	}

	override protected @property GLuint getHandle() const @nogc {
		return handle_;
	}
	private:
	GLuint handle_;
}

class ShaderProgram {

	this() {
		handle_ = glCreateProgram();
	}

	~this() {
		glDeleteProgram(handle_);
	}

	void attachShader(const(Shader) shader) {
		glAttachShader(handle_, shader.getHandle);
		version (GLDebug) checkError();
	}

	void detachShader(const(Shader) shader) {
		glDetachShader(handle_, shader.getHandle);		
		version (GLDebug) checkError();
	}

	void link() {
		glLinkProgram(handle_);
		version (GLDebug) checkError();

		GLint success;
		glGetProgramiv(handle_, GL_LINK_STATUS, &success);
		version (GLDebug) checkError();

		if (!success) {
			throw new GLError(GLError.Code.CompilerError, "Error Linking Shader Program");
		}
	}

	private static string funcname (string base, size_t num, in char[] suffix) {
		import std.exception;
		auto retval = new char[](base.length + 3);
		retval[0..base.length] = base[];
		retval[9] = cast(char) cast(ubyte)(48+num);
		retval[10..11] = suffix[0..1];
		retval[$-1] = 'v';

		return assumeUnique(retval);
	}
		
	static void setUniform(T) (GLuint index, in T value) @nogc if (isGLNumber!T || IsVectorType!T || (isStaticArray!T && (isGLNumber!(ElementType!T) || IsVectorType!(ElementType!T)))){		
		static if (isVectorType!T) {
			static if (isIntegral!(vectorComponentType!T)) {
				alias TrueType = int;
			} else {
				alias TrueType = float;
			}
			enum count = 1;
			enum size = vectorSize!T;
			immutable string suffix = TrueType.stringof[0..1] ;

			static if (is(vectorComponentType!T == int) || is(vectorComponentType!T == uint) || is(vectorComponentType!T == float)) {
				alias assignval = punVector(value);
			}	else {
				TrueType[vectorSize!T] assignval;

				foreach (size_t i, v; punVector(value)) {
					assignval[i] = cast(TrueType)v;
				}
			}
		} else static if (isGLNumber!T) {
			static if (isIntegral!(T)) {
				alias TrueType = int;
			} else {
				alias TrueType = float;
			}
			enum count = 1;
			enum size = 1;
			immutable string suffix = TrueType.stringof[0..1] ;

			TrueType[1] assignval;
			assignval[0] = cast(TrueType)value;

		} else static if (isStaticArray!T) {
			alias TT = ElementType!T;
			static if (isVectorType!TT) {
				static if (isIntegral!(vectorComponentType!TT)) {
					alias TrueType = int;
				} else {
					alias TrueType = float;
				}
				enum count = T.init.length;
				enum size = vectorSize!TT;
				immutable string suffix = TrueType.stringof[0..1] ;

				static if (is(vectorComponentType!TT == int) || is(vectorComponentType!TT == uint) || is(vectorComponentType!TT == float)) {
					alias assignval = value;
				}	else {
					TrueType[vectorSize!TT][T.init.length] assignval;

					foreach (size_t j, vv; value) {
						foreach (size_t i, v; punVector(vv)) {
							assignval[j][i] = cast(TrueType)v;
						}
					}
				}
			} else static if (isGLNumber!TT) {
				static if (isIntegral!(TT)) {
					alias TrueType = int;
				} else {
					alias TrueType = float;
				}
				enum count = T.init.length;
				enum size = 1;
				immutable string suffix = TrueType.stringof[0..1] ;

				static if (is(vectorComponentType!TT == int) || is(vectorComponentType!TT == uint) || is(vectorComponentType!TT == float)) {
					alias assignval = value;
				}	else {
					TrueType[T.init.length] assignval;

					foreach (size_t i, v; value) {
						assignval[i] = cast(TrueType)v;
					}
				}
			}
		}
		alias uniformSet = mixin(funcname("glUniform", size, suffix));


		uniformSet(index, count, assignval.ptr);
	}
	static void setUniformMatrix(T)(GLuint index, in T value)  @nogc if (isMatrix!T && is(MatrixType!T == float)  && MatrixSize!T > 1)  {
		static if (MatrixSize!T == 2) {
			glUniformMatrix2fv(index, 1, false, punMatrix(value).ptr);
		} else static if (MatrixSize!T == 3) {
			glUniformMatrix3fv(index, 1, false,  punMatrix(value).ptr);
		} else static if (MatrixSize!T == 4) {
			glUniformMatrix4fv(index, 1, false,  punMatrix(value).ptr);
		} else static assert (0);
	}

	static void setUniformMatrix(T)(GLuint index, in T value)  @nogc if (isMatrix!T && !is(MatrixType!T == float) && is (MatrixType!T : float) && MatrixSize!T > 1)  {
		float[MatrixSize!T] floatval;

		foreach  (size_t i, ref v; punMatrix(value)) {
			floatval[i] = v;
		}

		static if (floatval.length == 4) {
			glUniformMatrix2fv(index, 1, false, floatval.ptr);
		} else static if (floatval.length == 9) {
			glUniformMatrix3fv(index, 1, false, floatval.ptr);
		} else static if (floatval.length == 16) {
			glUniformMatrix4fv(index, 1, false, floatval.ptr);
		} else static assert (0);
	}

	void setUniformMatrix(T)(const(char)[] name, in T value) const @nogc {
		setUniformMatrix(getUniformLocation(name), value);
	}

	void setUniform(T)(const(char)[] name, in T value) const @nogc {
		setUniform(getUniformLocation(name), value);
	}

	auto getUniform(T)(GLint location) const @nogc if (is(T == float) || is(T == int) || is(T==uint)) {
		T[16] retval;

		static if (is(T == int) || is(T==uint)) 
			glGetUniformiv(handle_, location, retval.ptr);
		else static if (is(T == float)) 
			glGetUniformfv(handle_, location, retval.ptr);
		
		version (GLDebug) checkError();

		return retval;
	}

	final auto getUniform(T)(const(char)[] name) const @nogc {
		return getUniform!T(getUniformLocation(name), value);
	}

	final auto getUniformLocation(const(char)[] name)  const @nogc {
		return glGetUniformLocation(this?handle_:0, name.ptr);
	}

	static void setAttribute(string base, T) (GLuint index, in T value) @nogc if (isVertexComponent!T ){		
		static if (isVectorType!T) {
			alias TrueType = float;

			enum size = vectorSize!T;
			immutable string suffix = TrueType.stringof[0..1] ;

			static if (is(vectorComponentType!T == float)) {
				alias assignval = punVector(value);
			}	else {
				TrueType[vectorSize!T] assignval;

				foreach (size_t i, v; punVector(value)) {
					assignval[i] = cast(TrueType)v;
				}
			}
		} else static if (isGLNumber!T) {
			alias TrueType = float;

			enum size = 1;
			immutable string suffix = TrueType.stringof[0..1] ;

			TrueType[1] assignval;
			assignval[0] = cast(TrueType)value;

		} else static if (isStaticArray!T) {
			alias TrueType = float;

			enum size = T.init.length;
			immutable string suffix = TrueType.stringof[0..1] ;

			static if (is(TrueType == ElementType!T)) {
				alias assignval = value;
			} else {
				TrueType[value.length] assignval;

				foreach (size_t i, ref v; value) {
					assignval[i] = v;
				}
			}

		}

		alias attributeSet = mixin(funcname("glVertexAttrib", size, suffix));


		attributeSet(index, assignval.ptr);
		version (GLDebug) checkError();
	}

	void setAttribute(T) (in char[] name, in T value) const @nogc {
		setAttribute(getAttributeLocation(name), value);
	}

	auto getAttribute(T)(GLint location, GLenum parameterName) const @nogc if (is(T == float) || is(T == int) ||  is(T==uint)) {
		T[4] retval;

		static if (is(T == int) || is(T==uint)) 
			glGetVertexAttribiv(location, parameterName, retval.ptr);
		else static if (is(T == float)) 
			glGetVertexAttribfv(location, parameterName, retval.ptr);
		
		version (GLDebug) checkError();
		return retval;
	}

	auto getAttribute(T)(in char[] name, GLenum parameterName) {
		return getAttribute!T(getAttributeLocation(name), parameterName);
	}

	auto getAttributeLocation(in char[] name) const @nogc {
		return glGetAttribLocation(handle_, name.ptr);
	}

	auto getLog() const {
		import std.exception;
		char[] retval;
		GLint loglen;
		glGetProgramiv(handle_, GL_INFO_LOG_LENGTH, &loglen);
		version (GLDebug) checkError();

		retval.length = loglen;
		GLint retlen;

		glGetProgramInfoLog(handle_, loglen, &retlen, retval.ptr);
		version (GLDebug) checkError();

		return assumeUnique(retval);
	}

	void validate() {
		glValidateProgram(handle_);

		checkError();
	}

	private:

	GLuint handle_;
}

void use(const(ShaderProgram) prog) {
	glUseProgram(prog?prog.handle_:0);
}


void loadBinary(const(Shader)[] shaders, GLenum binaryFormat, const(void)[] data) @nogc {
	GLuint[512] shadernums;
	assert (shaders.length < 512);

	foreach (size_t i, S; shaders) {
		shadernums = S.getHandle;
	}
	glShaderBinary(cast(GLsizei)shaders.length, shadernums.ptr, binaryFormat, data.ptr, cast(GLsizei)data.length);
}