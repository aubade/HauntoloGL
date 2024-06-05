module hauntologl.gl.draw;

import hauntologl.gl.config;
import hauntologl.gl.vertices;
import hauntologl.gl.traits;


enum Primitive:GLenum {
	Points = GL_POINTS,
	Lines = GL_LINES,
	LineStrip = GL_LINE_STRIP,
	LineLoop = GL_LINE_LOOP,
	Triangles = GL_TRIANGLES,
	TrianglesStrip = GL_TRIANGLE_STRIP,
	TrianglesFan = GL_TRIANGLE_FAN
}

struct GL {
	enum Blend {
		Add = GL_FUNC_ADD,
		Subtract = GL_FUNC_SUBTRACT,
		ReverseSubtract = GL_FUNC_REVERSE_SUBTRACT
	}
	enum Color {
		Zero = GL_ZERO,
		One = GL_NONE,
		Src = GL_SRC_COLOR,
		OneMinusSrc = GL_ONE_MINUS_SRC_COLOR,
		Dst = GL_DST_COLOR,
		OneMinusDst = GL_ONE_MINUS_DST_COLOR,
		SrcAlpha = GL_SRC_ALPHA,
		OneMinusSrcAlpha = GL_ONE_MINUS_SRC_ALPHA,
		DstAlpha = GL_DST_ALPHA,
		OneMinusDstAlpha = GL_ONE_MINUS_DST_ALPHA,
		Constant = GL_CONSTANT_COLOR,
		OneMinusConstant = GL_ONE_MINUS_CONSTANT_COLOR,
		ConstantAlpha = GL_CONSTANT_ALPHA,
		OneMinusConstantAlpha = GL_ONE_MINUS_CONSTANT_ALPHA,
		AlphaSaturate = GL_SRC_ALPHA_SATURATE
	}
	enum Setting {
		Blend = GL_BLEND,
		CullFace = GL_CULL_FACE,
		DepthTest = GL_DEPTH_TEST,
		Dither = GL_DITHER,
		PolygonOffsetFill = GL_POLYGON_OFFSET_FILL,
		SampleAlphaCoverage = GL_SAMPLE_ALPHA_TO_COVERAGE,
		SampleCoverage = GL_SAMPLE_COVERAGE,
		ScissorTest = GL_SCISSOR_TEST,
		StencilTest = GL_STENCIL_TEST
	}
	enum Culling {
		Front = GL_FRONT,
		Back = GL_BACK,
		Both = GL_FRONT_AND_BACK
	}
	enum Function {
		Never = GL_NEVER,
		LessThan = GL_LESS,
		EqualTo = GL_EQUAL,
		LessThanOrEqualTo = GL_LEQUAL,
		GreaterThan = GL_GREATER,
		NotEqualTo = GL_NOTEQUAL,
		GreaterThanOrEqualTo = GL_GEQUAL,
		Always = GL_ALWAYS
	}
	enum Op {
		Keep = GL_KEEP,
		Zero = GL_ZERO,
		Replace = GL_REPLACE,
		Increment = GL_INCR,
		IncrementWrap = GL_INCR_WRAP,
		Decrement = GL_DECR,
		DecrementWrap = GL_DECR_WRAP,
		Invert = GL_INVERT
	}
	enum Winding {
		Clockwise = GL_CW,
		CounterClockwise = GL_CCW
	}

	static void blendFunc (Color src = Color.One, Color dst = Color.Zero) {
		glBlendFunc(src, dst);
		version (GLDebug) checkError();
	}

	static void blendFunc(Color srcRGB, Color dstRGB, Color srcAlpha, Color dstAlpha) {
		glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
		version (GLDebug) checkError();
	}

	static void blendEquation (Blend mode) {
		glBlendEquation(mode);
		version (GLDebug) checkError();
	}

	static void blendEquation (Blend modeRGB, Blend modeAlpha) {
		glBlendEquationSeparate(modeRGB, modeAlpha);
		version (GLDebug) checkError();
	}

	static void setting(Setting set, bool value) {
		if (value)
			glEnable(set);
		else
			glDisable(set);
		version (GLDebug) checkError();
	}

	static bool getsetting(Setting set)  {
		return glIsEnabled(set) == GL_TRUE;
	}

	static void blendColor(T)(T color) if (isVertexComponent!T && VertexComponentSize!T == 4) {
		static if (is(VertexType!T == GLfloat)) {
			GLfloat[4] col = punVector(color);
		} else {
			auto temp = punVector(color);
			GLfloat[4] col = [temp[0]/cast(GLfloat)ubyte.max,temp[1]/cast(GLfloat)ubyte.max,temp[2]/cast(GLfloat)ubyte.max,temp[3]/cast(GLfloat)ubyte.max];
		}

		glBlendColor(col[0], col[1], col[2], col[3]);
		version (GLDebug) checkError();
	}

	static void culling(Culling val) {
		glCullFace(val);
		version (GLDebug) checkError();
	}

	void frontFace (Winding dir) {
		glFrontFace(dir);
		version (GLDebug) checkError();
	}

	static void depthFunction (Function f) {
		glDepthFunc(f);
		version (GLDebug) checkError();
	}

	static void depthMask(bool val) {
		glDepthMask (val);
		version (GLDebug) checkError();
	}

	static void depthRange(GLclampf near, GLclampf far) {
		glDepthRangef(near, far);
		version (GLDebug) checkError();
	}

	static void stencilFunction (Function f, GLint reff, GLuint mask)  {
		glStencilFunc(f, reff, mask);
		version (GLDebug) checkError();
	}

	static void stencilFunction (Culling face, Function f, GLint reff, GLuint mask) {
		glStencilFuncSeparate(face, f, reff, mask);
		version (GLDebug) checkError();
	}

	static void stencilMask (GLuint mask) {
		glStencilMask(mask);
		version (GLDebug) checkError();
	}

	static void stencilMask(Culling face, GLuint mask) {
		glStencilMaskSeparate(face, mask);
		version (GLDebug) checkError();
	}

	static void stencilOp (Op stencilFail, Op depthFail, Op pass) {
		glStencilOp(stencilFail, depthFail, pass);
		version (GLDebug) checkError();
	}

	static void stencilOp (Culling face, Op stencilFail, Op depthFail, Op pass) {
		glStencilOpSeparate(face, stencilFail, depthFail, pass);
		version (GLDebug) checkError();
	}

	static void lineWidth (GLfloat width) {
		glLineWidth(width);
		version (GLDebug) checkError();
	}

	static void polygonOffset (GLfloat factor, GLfloat units) {
		glPolygonOffset(factor, units);
		version (GLDebug) checkError();
	}

	static void sampleCoverage (GLclampf value, GLboolean invert) {
		glSampleCoverage(value, invert);
		version (GLDebug) checkError();
	}

	static void scissor(GLint x, GLint y, GLsizei width, GLsizei height) {
		glScissor(x, y, width, height);
		version (GLDebug) checkError();
	}

	static void viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
		glViewport (x, y, width, height);
		version (GLDebug) checkError();
	}

	static void flush() {
		glFlush();
		version (GLDebug) checkError();
	}

	static void finish() {
		glFinish();
		version (GLDebug) checkError();
	}

	@property {
		static string vendor() {
			import core.stdc.string;
			import std.exception;
			auto temp = glGetString(GL_VENDOR);

			return assumeUnique(temp[0..strlen(temp)]);
		}

		static string renderer() {
			import core.stdc.string;
			import std.exception;
			auto temp = glGetString(GL_RENDERER);

			return assumeUnique(temp[0..strlen(temp)]);
		}

		static string GLversion() {
			import core.stdc.string;
			import std.exception;
			auto temp = glGetString(GL_VERSION);

			return assumeUnique(temp[0..strlen(temp)]);
		}

		static string GLSLversion() {
			import core.stdc.string;
			import std.exception;
			auto temp = glGetString(GL_SHADING_LANGUAGE_VERSION);

			return assumeUnique(temp[0..strlen(temp)]);
		}

		static string extensions() {
			import core.stdc.string;
			import std.exception;
			auto temp = glGetString(GL_EXTENSIONS);

			return assumeUnique(temp[0..strlen(temp)]);
		}
	}
}

void clear (T)(const(T) color = T.init, GLfloat depth = 1, GLint stencil = 0) if (isVertexComponent!T && VertexComponentSize!T == 4) {
	static if (is(VectorComponentType!T  == GLfloat)) {
		GLfloat[4] outcol = punVector(color);
	} else {
		auto temp = punVector(color);
		GLfloat[4] outcol = [temp[0]/cast(GLfloat)ubyte.max,temp[1]/cast(GLfloat)ubyte.max,temp[2]/cast(GLfloat)ubyte.max,temp[3]/cast(GLfloat)ubyte.max];
	}

	glClearDepthf(depth);
	glClearStencil(stencil);
	glClearColor(outcol[0], outcol[1], outcol[2], outcol[3]);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	version (GLDebug) checkError();
}

void draw (T, U)(const(InterleavedVAO!T) vertices, Primitive prim = Primitive.Triangles, size_t offset = 0, size_t len = 0, const(U)[] elements = GLubyte[].init) if (is(U == GLubyte) || is(U == GLushort)) {
	vertices.bind();

	if (vertices.elements !is null) {
		glDrawElements(cast(GLenum)prim,cast(GLint)(len==0?cast(GLint)vertices.numElements:len), vertices.elementType, cast(void*)(offset * vertices.elementType==GL_UNSIGNED_BYTE?1:2));
	} else if (elements.length > 0) {
		glDrawElements(cast(GLenum)prim, cast(GLint)elements.length, getGLType!U, elements.ptr + offset);
	} else {
		glDrawArrays(cast(GLenum)prim, cast(GLint)offset, cast(GLint)len);
	}
}

void draw (U, T...)(const(SeparatedVAO!(T)) vertices, Primitive prim = Primitive.Triangls, size_t offst = 0, size_t len = 0, const(U)[] elements = GLubyte[].init) if (is(U == GLubyte) || is(U == GLushort)) {
	vertices.bind();

	if (vertices.elements !is null) {
		glDrawElements(prim, vertices.numElements, vertices.elementType, cast(void*)(offset * vertices.elementType==GL_UNSIGNED_BYTE?1:2));
	} else if (elements.length > 0) {
		glDrawElements(prim, elements.length, getGLType!T, elements.ptr + offset);
	} else {
		glDrawArrays(prim, offset, len==0?vertices.numVertices:len);
	}
	version (GLDebug) checkError();
}

void drawArrays(const(void)[] data, Primitive prim = Primitive.Triangles) {
	glDrawArrays(prim, 0, cast(GLint)data.length);
}

void drawElements(T)(const(void)[] data, const(T)[] elements, Primitive prim = Primitive.Triangles) if (is(T == GLubyte) || is(T == GLushort)){
	glDrawElements(prim, elements.length, getGLType!T, elements,ptr);
}
