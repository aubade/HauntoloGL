module hauntologl.drawable;

import hauntologl.gl.draw;
import hauntologl.gl.textures;
import hauntologl.gl.shaders;
import hauntologl.gl.config;
import gl3n.linalg;

template isDrawable(T) {
	static if (is(T:Drawable)) {
		enum isDrawable = true;
	} /*else static if (__traits(compiles,const(T).init.bindDrawable())) {
		enum isDrawable = true;
	}*/ else static if (__traits(compiles, const(T).init.draw())) {
		enum isDrawable = true;
	} else {
		enum isDrawable = false;
	}
}

template isDrawTarget(T) {
	static if (is(T:DrawTarget)) {
		enum isDrawTarget = true;
	} else static if (__traits(compiles, RenderStates.init == const(T).init.getRenderStates())) {
		static if (__traits(compiles, const(T).init.bindTarget())) {
			enum isDrawTarget = true;
		}  else static if (__traits(compiles, const(T).init.draw(Drawable.init))) {
			enum isDrawTarget = true;
		}
	} else {
		enum isDrawTarget = false;
	}
}

interface Drawable {
	void bindDrawable(DrawTarget) const;
}

interface DrawTarget {
	void bindTarget();

	void draw(T)(const(T) obj) {
		this.bindTarget();
		obj.draw();
	}
}

pure nothrow @nogc:

alias Coord = Vector!(float, 2);
alias Coordi = Vector!(uint, 2);
alias Coords = Vector!(int, 2);
//alias CoordFlag = Vector!(bool, 2);
alias Matrix3 = Matrix!(float, 3, 3);
alias Matrix4 = Matrix!(float, 4, 4);
alias Color = Vector!(ubyte, 4);

struct CoordFlag {
	union {
		struct {
			bool x, y;
		}
		bool[2] xy;
	}

	this (bool newX, bool newY) {
		x = newX;
		y = newY;
	}

	this (bool[2] newXY) {
		xy = newXY;
	}

	alias xy this;
}

struct Rect(T) {
	Vector!(T, 2) pos;
	Vector!(T, 2) size;

	alias x = pos.x;
	alias y = pos.y;
	alias w = size.x;
	alias h = size.y;
}


struct Transform2D {
	Matrix4 matrix = Matrix4.identity;

	this (const(Matrix4) newmat) nothrow pure @safe @nogc inout{
		matrix = newmat;
	}

	this (float[9] newmat)	nothrow pure @safe @nogc  inout {
		this(newmat[0], newmat[1],newmat[2],newmat[3],newmat[4],newmat[5],newmat[6],newmat[7],newmat[8]);
	}

	this (float a00, float a01, float a02, float a10, float a11, float a12, float a20, float a21, float a22)nothrow pure @safe @nogc  inout {
		matrix = Matrix4(	a00, a10, 0, a20,
											a01, a11, 0, a21,
											0, 0, 1, 0,
											a02, a12, 0, a22);				
	}

	Coord transformPoint (const(Coord) point) nothrow pure @safe @nogc const {
		return Coord(matrix[0][0] * point.x + matrix[1][0] * point.y + matrix[3][0],
								  matrix[0][1] * point.x + matrix[1][1] * point.y + matrix[3][1]);
	}

	auto transformRect (const(Rect!float) rect) nothrow pure @safe @nogc const {
		import std.algorithm;
		Coord topLeft = transformPoint(rect.pos);
		Coord bottomRight = transformPoint(rect.pos + rect.size);
		if (bottomRight.x < topLeft.x) swap (bottomRight.x, topLeft.x);
		if (bottomRight.y < topLeft.y) swap (bottomRight.y, topLeft.y);

		return Rect!float (topLeft, bottomRight - topLeft);
	}

	Transform2D inverse() nothrow pure @safe @nogc const {
		return Transform2D(matrix.inverse);
	}

	Transform2D translate (Coord newval) nothrow pure @safe @nogc {
		Transform2D transmatrix = Transform2D(
			1, 0, 	newval.x,
			0, 1, newval.y,
			0, 0, 1
		);

		return combine(transmatrix);
	}

	Transform2D scale (Coord newval, Coord center = Coord(0, 0)) nothrow pure @safe @nogc  {
		Transform2D transmatrix = Transform2D(
			newval.x, 0, 	center.x * (1 - newval.x),
			0, newval.y, center.y * (1 - newval.y),
			0, 0, 1
		);

		return combine(transmatrix);
	}

	Transform2D rotate(float newval, const(Coord) center = Coord(0,0)) nothrow pure @safe @nogc  {
		import std.math;
		auto sinval = sin(newval);
		auto cosval = cos(newval);

		Transform2D transmatrix = Transform2D(
			cosval, -sinval, center.x * (1 - cosval) + center.y * sinval,
			sinval, cosval, center.y * (1 - cosval) - center.x * sinval,
			0, 0, 1
		);

		return combine(transmatrix);
	}

	Transform2D skew (Coord newval)nothrow pure @safe @nogc  {
		import std.math;
		Transform2D transmatrix = Transform2D(
			1, newval.x, 	0,
			newval.y, 1, 0,
			0, 0, 1
		);

		return combine(transmatrix);
	}

	static auto identity() nothrow pure @safe @nogc {
		return Matrix4.identity;
	}

	auto combine (const(Transform2D) rhs) nothrow pure @safe @nogc  {
		auto a = cast(const(float)[])matrix.matrix;
		auto b = cast(const(float)[])rhs.matrix.matrix;
		
		this = Transform2D(
			a[0] * b[0]  + a[4] * b[1]  + a[12] * b[3],
			a[0] * b[4]  + a[4] * b[5]  + a[12] * b[7],
			a[0] * b[12] + a[4] * b[13] + a[12] * b[15],
			a[1] * b[0]  + a[5] * b[1]  + a[13] * b[3],
			a[1] * b[4]  + a[5] * b[5]  + a[13] * b[7],
			a[1] * b[12] + a[5] * b[13] + a[13] * b[15],
			a[3] * b[0]  + a[7] * b[1]  + a[15] * b[3],
			a[3] * b[4]  + a[7] * b[5]  + a[15] * b[7],
			a[3] * b[12] + a[7] * b[13] + a[15] * b[15]
		);
		return this;
	} 

	auto opUnary (string op) () nothrow pure @safe @nogc  const if (op == "!")   {
		return inverse;
	}

	auto opBinary (string op) (const(Transform2D) rhs)  nothrow pure @safe @nogc const if (op =="*")  {
		auto retval = this;
		return retval.combine(rhs);
	}

	alias matrix this;

	unittest {
			import std.stdio;
			import std.math;
			assert (Transform2D.init.translate(Coord(-10, 10)).transformPoint(Coord(0, 0)) == Coord(-10, 10));
			assert (Transform2D.init.scale(Coord(3, 2)).transformPoint(Coord(1, -1)) == Coord(3, -2));
			assert (Transform2D.init.rotate(PI/2).transformPoint(Coord(1, 0)).y == 1);
			assert (abs(Transform2D.init.rotate(PI/2).transformPoint(Coord(1, 0)).x) <= float.epsilon);
			assert (Transform2D.init.skew(Coord(1, 0)).transformPoint(Coord(0,1)) == Coord(1, 1));
			assert (Transform2D.init.skew(Coord(0, 1)).transformPoint(Coord(1,0)) == Coord(1, 1));
	}
}




struct BlendMode {
	enum:BlendMode {
		Alpha = BlendMode(GL.Color.SrcAlpha, GL.Color.OneMinusSrcAlpha, GL.Blend.Add, GL.Color.One, GL.Color.OneMinusSrcAlpha, GL.Blend.Add),
		Add = BlendMode(GL.Color.SrcAlpha, GL.Color.One, GL.Blend.Add, GL.Color.One, GL.Color.One, GL.Blend.Add),
		Multiply = BlendMode(GL.Color.Dst, GL.Color.Zero, GL.Blend.Add),
		None = BlendMode(GL.Color.One, GL.Color.Zero, GL.Blend.Add)
	}

	GL.Color srcRGB;
	GL.Color dstRGB;
	GL.Blend rgbEquation;
	GL.Color srcAlpha;
	GL.Color dstAlpha;
	GL.Blend alphaEquation;

	this(GL.Color srcRGB_, GL.Color dstRGB_, GL.Blend rgbEquation_, GL.Color srcAlpha_, GL.Color dstAlpha_, GL.Blend alphaEquation_) {
		srcRGB = srcRGB_;
		srcAlpha = srcAlpha_;
		dstRGB = dstRGB_;
		dstAlpha = dstAlpha_;
		rgbEquation = rgbEquation_;
		alphaEquation = alphaEquation_;
	}

	this(GL.Color src, GL.Color dst, GL.Blend equation = GL.Blend.Add) {
		srcRGB = src;
		srcAlpha = src;
		dstRGB = dst;
		dstAlpha = dst;
		rgbEquation = equation;
		alphaEquation = equation;
	}

	void use() {
		glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
		glBlendEquationSeparate(rgbEquation, alphaEquation);
	}
}


struct StencilMode {
	GL.Function comparison = GL.Function.Always;
	GL.Op 	updateOp = GL.Op.Keep;
	uint reference = 0;
	uint mask = 0;
	bool stencilOnly;

	void use() {
		GL.stencilOp(GL.Op.Keep, updateOp, updateOp);
		GL.stencilFunction(comparison, reference, mask);
	}
}

import hauntologl.gl.traits;
static assert (isMatrix!(Matrix4));
pragma(msg, MatrixType!Matrix4);

struct RenderStates {
	import std.typecons;
	BlendMode blending = BlendMode.Alpha;
	StencilMode stencil;
	Transform2D transform = Transform2D.identity;
	Rebindable!(const(Texture)) texture;
	Rebindable!(const(ShaderProgram)) shader;
	GLint transformPos = -1;

	@trusted void use() {
		blending.use();
		stencil.use();
		shader.use();
		if (transformPos < 0) shader.setUniformMatrix("transform", transform.matrix);
			else shader.setUniformMatrix(transformPos, transform.matrix);
		texture.bind();
	}
}