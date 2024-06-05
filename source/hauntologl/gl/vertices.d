/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.gl.vertices;

import hauntologl.gl.config;
import hauntologl.gl.shaders;
import hauntologl.gl.traits;
import std.meta;
import std.traits;
import std.typecons;
import hauntologl.gl.config;

class VBO {
	public:
		enum Type {
			Stream = GL_STREAM_DRAW,
			Static = GL_STATIC_DRAW,
			Dynamic = GL_DYNAMIC_DRAW
		}

		static VBO[] createMultiple(GLsizei number)  {
			VBO[] retval;
			GLuint[] handles;

			retval.length = number;
			handles.length = number;
			glGenBuffers(number, handles.ptr);
			version (GLDebug) checkError();

			foreach (size_t i, ref B; retval) {
				B = new VBO(handles[i]);
			}

			return retval;
		}

		static void unbind(bool bindElements = false)  @nogc {
			glBindBuffer(bindElements?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, 0);
			version (GLDebug) checkError();
		}

		this()  const @nogc {
			uint tempHandle;
			glGenBuffers(1, &tempHandle);
			handle_ = tempHandle;
			version (GLDebug) checkError();
		}

		this() @nogc {
			glGenBuffers(1, &handle_);
			version (GLDebug) checkError();
		}

		~this() {
			glDeleteBuffers(1, &handle_);
			version (GLDebug) checkError();
		}

		void bind() const @nogc {
			glBindBuffer(elements_?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, handle_);
			version (GLDebug) checkError();
		}

		void preAllocate(size_t size, Type usage, bool bindElements) @nogc  {
			elements_ = bindElements;
			bind();
			glBufferData(elements_?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, size, null, usage);
		}

		void update(const(void)[] data, Type usage)  @nogc const {
			bind();
			glBufferData(elements_?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, data.length, data.ptr, usage);
			version (GLDebug) checkError();
		}

		void update(const(void)[] data, Type usage, bool bindElements)  @nogc  {
			elements_ = bindElements;
			bind();
			glBufferData(elements_?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, data.length, data.ptr, usage);
			version (GLDebug) checkError();
		}

		void updateSub(const(void)[] data, size_t offset, bool bindElements)  @nogc {
			if (data.length == 0) return;
			version (GLDebug) assert(bendElements == elements_);
			version (GLDebug) assert(offset + data.length < length);
				else bind();

			glBufferSubData(elements_?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, offset, data.length, data.ptr);
			version (GLDebug) checkError();
		}

		void updateSub(const(void)[] data, size_t offset) const @nogc {
			version (GLDebug) assert(offset + data.length < length);
				else bind();

			glBufferSubData(elements_?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, offset, data.length, data.ptr);
			version (GLDebug) checkError();
		}

		@property auto length() const  @nogc {
			GLint retval;
			bind();
			glGetBufferParameteriv(elements_?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER, GL_BUFFER_SIZE, &retval);

			return retval;
		}


	private:
		this(GLuint existingHandle) {
			handle_ = existingHandle;
		}

		GLuint handle_;
		bool elements_;
}

struct InterleavedVAO(T) if (isVertexFormat!T) {
	static GLuint[T.tupleof.length] indices;
	VBO.Type usage = VBO.Type.Static;
	VBO vertices;
	VBO elements;
	size_t numElements;
	GLenum elementType;

	void update(T)(const(T)[] data)  {
		vertices.update(data, usage, false);
	}

	void updateSub(T)(const(T)[] data, size_t offset)  const @nogc {
		if (data.length == 0) return;

		vertices.updateSub(data, offset, false);
	}

	void updateElements(U)(const(U)[] data)  if (is(U == GLubyte) || is(U == GLushort)) {
		numElements = data.length;

		if (data.length == 0) {
			elements = null;
			elementType = 0;
		} else {
			elementType = getGLType!U;
			if (elements is null) 
				elements = new VBO();
			elements.update(data, usage, true);
		}
	}

	void updateElementsConst(U)(const(U)[] data)  const @nogc if (is(U == GLubyte) || is(U == GLushort))  {
		assert(elements);
		assert(numElements == data.length);
		assert(getGLType!U == elementType);

		elements.update(data, usage);
	}

	void updateElementsSub(U)(const(U)[] data, size_t offset) const @nogc if (is(U == GLubyte) || is(U == GLushort)){
		assert (data.length + offset < numElements);
		assert(getGLType!U == elementType);
		elements.updateSub(data, offset);
	}

	void bind() const @nogc  {
		vertices.bind();

		hauntologl.gl.vertices.bind!T(null);

		if (elements) elements.bind();
	}

	static void useShader(const(ShaderProgram) shader, bool force = false) {
		if (!force && indices != GLuint[T.init.tupleof.length].init) return;
		if (shader) {
			foreach (size_t i, name; FieldNameTuple!T) {
				indices[i] = shader.getAttributeLocation(name);
			}
		} else {
			foreach (size_t i, ref idx; indices) {
				idx = cast(GLuint)i;
			}
		}
	}
}

struct SeparatedVAO(bool oneVBO, AttribList...) if ((AttribList.length == 1 && isVertexArrayStruct!T[0]) || (T.length <= MAX_VERTEX_COMPONENTS && allSatisfy!(isVertexComponent, T))) {
	private static string genenum() {
		import std.conv;
		string retval = "enum Attrib {\n	";

		foreach (size_t i, type; Attribs) {
			retval ~= "	" ~ type.stringof ~" = " ~to!string(i) ~",\n	";
		}

		return retval ~ "}";
	}

	static if (AttribList.length == 1 && isVertexArrayStruct!(AttribList)[0]) {
		alias Attribs = FieldTypeTuple!(AttribList[0]);
	} else {
		alias Attribs = AttribList;
	}

	mixin (genenum);
	static GLuint[vectorSize!T] indices;
	static bool[Attribs.length] normalized;
	static if (oneVBO) static size_t[Attribs.length] offsets;


	VBO.Type usage = VBO.Type.Dynamic;
	static if (oneVBO) {
		VBO vertices;
	} else {
		VBO[Attribs.length] vertices;
	}
	VBO elements;
	size_t numVertices;
	size_t numElements;
	GLenum elementType;

	static if (oneVBO) {
		size_t offsetOf(size_t typeIndex) {
			size_t retval = 0;
			foreach (size_t i, T; Attribs) {
				if (i == typeIndex) break;
				retval += numVertices * T.sizeof;
			}

			return retval;
		}
	}

	static if (oneVBO) void makeVBOs(scope VBO function() maker = () {return new VBO();}) {
		foreach (ref v; vertices) {
			v = maker();
		}
	}

	void update(Attribs)(const(Attribs) data) const @nogc {
		numVertices = data[0].length;
		static if (oneVBO) {
			size_t totallen;
			foreach (size_t i, d; data) {
				assert (d.length = numVertices);
				numVertices = max(numVertices, d.length);
				totallen += d.length * ElementType!(typeof(d)).sizeof;

				static if (i + 1 < offsets.length) offsets[i + 1] = d.length * ElementType!(typeof(d)).sizeof;
			}
			vertices.bind();
			vertices.preAllocate(totallen, usage);
			foreach (size_t i, d; data) {
				vertices.updateSub(d, offsets[i], false);
			}

		} else {
			foreach (size_t i, d; data) {
				assert (d.length = numVertices);
				numVertices = max(numVertices, d.length);
				vertices[i].update(d, usage, false);
			}
		}

	}

	void updateOne(T)(const(T)[] data, GLuint index, VBO.Type usage = VBO.Type.Static)  {
		assert (data.length == numVertices);

		static if (oneVBO) {
			vertices.updateSub(data, offsets[index]);
		} else {
			vertices[index].update(data, usage, false);
		}
	}

	void updateSub(T)(const(T)[] data, size_t offset)  const @nogc {
		if (data.length == 0) return;
	}

	void updateElements(U)(const(U)[] data)  if (is(U == GLubyte) || is(U == GLushort)) {
		numElements = data.length;
		if (data.length == 0) {
			elements = null;
			elementType = 0;
		} else {
			elementType = getGLType!U;
			if (elements is null) 
				elements = new VBO();
			elements.update(data, usage, true);
		}
	}

	void updateElementsConst(U)(const(U)[] data)  const @nogc if (is(U == GLubyte) || is(U == GLushort))  {
		assert(elements);
		assert(numElements == data.length);
		assert(getGLType!U == elementType);

		elements.update(data, usage);
	}

	void updateElementsSub(U)(const(U)[] data, size_t offset) const @nogc if (is(U == GLubyte) || is(U == GLushort)){
		assert (data.length + offset < numElements);
		assert(getGLType!U == elementType);
		elements.updateSub(data, offset);
	}

	void bind(const(ShaderProgram) shader = null) {

		static if (oneVBO)
			vertices.bind();

		foreach (size_t i, A; Attribs) {
			static if (oneVBO) {
				glVertexAttribPointer(indices[i], VertexComponentSize!A, getGLType!A, normalized[i], A.sizeof, cast(void*)offsets[i]);
				glEnableVertexAttribArray(ptr);
			} else {
				vertices[i].bind();
				glEnableVertexAttribArray(indices[i]);
				glVertexAttribPointer(indices[i], VertexComponentSize!A, getGLType!A, normalized[i], A.sizeof, null);
			}
		}

		if (elements) elements.bind();
	}

	static void useShader(const(ShaderProgram) shader, bool force = false) {
		if (!force && indices != GLuint[vectorSize!T].init) return;
		if (shader) {
			foreach (size_t i, ref idx; indices) {
				idx = shader.glGetAttribLocation(Attribs[i].stringof);
			}
		} else {
			foreach (size_t i, ref idx; indices) {
				idx = i;
			}
		}
	}
}

void bind(T)(const(T)[] data) if (isVertexFormat!T) {
		T temp;
		foreach (size_t i, ref v; temp.tupleof) {
			glVertexAttribPointer(InterleavedVAO!(T).indices[i], VertexComponentSize!(typeof(v)), getGLType!(VectorComponentType!(FieldTypeTuple!T[i])), hasUDA!(v, Normalized), T.sizeof, cast(void*)(cast(size_t)(data.ptr) + temp.tupleof[i].offsetof));
			glEnableVertexAttribArray(InterleavedVAO!(T).indices[i]);
		}
}

void bind(VAOtype, T)(const(T)[] data, GLuint index) if (isInstanceOf!(SeparatedVAO, VAOtype) && staticIndexOf!(T, VAOType.Attribs) >= 0){
	assert (index < VAOType.Attribs.length);
	version (GLDebug) foreach (size_t i, CheckT; VAOType.Attribs) {
		if (i == index) assert (is(T == CheckT));
	}
	glEnableVertexAttribArray(index);
	glVertexAttribPointer(index, VertexComponentSize!T, getGLType!(VectorComponentType!T), VAOType.normalized[index],  T.sizeof, data.ptr);
}

void unbindAttribs() {
	foreach (size_t i; 0..MAX_VERTEX_COMPONENTS) {
		glDisableVertexAttribArray(cast(GLuint)i);
	}
}


