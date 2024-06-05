/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.gl.traits;

import hauntologl.gl.config;
import std.traits;
import std.range;
import std.meta;
import hauntologl.gl.config;
import std.file;

template isGLNumber(T) {
	static if (isNumeric!T &&  (isIntegral!T || is(T==float))) {
		enum isGLNumber = true;
	} else {
		enum isGLNumber = false;
	}
}

enum isOrArrayOf(T, U) = is(T == U) || (isStaticArray!U && is(T == ElementType!U));

template isVectorType(T) {
	static if (!is(T == struct)) {
		enum isVectorType = false;
	} else {
		//Figure out what kind of data we have in the vector. 
		static if (isStaticArray!(FieldTypeTuple!(T)[0])) {
			alias TT = ElementType!(FieldTypeTuple!(T)[0]);
		} else {
			alias TT = FieldTypeTuple!(T)[0];
		}
		
		//Curry the template so we can pass it to std.meta.allSatisfy
		enum isTOrArrayOf(U) = isOrArrayOf!(TT, U);

		//Parametrs we test for:
		//We only allow GLES 2.0 compatible numbers
		//We only allow scalars or static arrays of the same type within the array
		//The struct must be tightly packed
		//It must have 4 components or less.
		//Basically, it needs to safely be type punnable into a static array.
		
		static if (!isGLNumber!TT || 
						!(allSatisfy!(isTOrArrayOf, FieldTypeTuple!(T))) ||
						T.alignof > TT.sizeof ||
						 T.sizeof > TT.sizeof * MAX_VECTOR_LENGTH) {
			enum isVectorType = false;
		} else {
			enum isVectorType = true;
		}
	}
}

template VectorComponentType(T) if (isVertexComponent!T) {
	static if (isNumeric!T) {
		alias VectorComponentType = T;
	} else 	static if (isStaticArray!T) {
		alias VectorComponentType = ElementType!T;
	} else static if (is(T == struct)) {
		static if (isNumeric!(FieldTypeTuple!T[0])) {
			alias VectorComponentType = typeof(T.init.tupleof[0]);
		} else static if (isStaticArray!(FieldTypeTuple!T[0])) {
			alias VectorComponentType = ElementType!(FieldTypeTuple!T[0]);
		} else alias VectorComponentType = void;
	} else {
		alias VectorComponentType = void;
	}
}

template getGLType(T) {
	version (GLES_20) {}
		else alias GLfixed = int;

	static if (is(T == GLbyte))
		enum getGLType = GL_BYTE;
	else static if (is(T == GLubyte))
		enum getGLType = GL_UNSIGNED_BYTE;
	else static if (is(T == GLshort))
		enum getGLType = GL_SHORT;
	else static if (is(T == GLushort))
		enum getGLType = GL_UNSIGNED_SHORT;
	else static if (is(T == GLuint))
		enum getGLType = GL_UNSIGNED_INT;
	else static if (is(T == GLfixed))
		enum getGLType = GL_FIXED;
	else static if (is(T == GLfloat))
		enum getGLType = GL_FLOAT;
	else
		static assert (0);
}

template vectorSize(T) if (isVertexComponent!T) {
	static if (isNumeric!T) {
		enum vectorSize = 1;
	} else static if (isStaticArray!T) {
		enum vectorSize = T.init.length;
	} else static if (is(T == struct)) {
		static assert (T.sizeof % VectorComponentType!(T).sizeof == 0);
		enum vectorSize = T.sizeof / VectorComponentType!(T).sizeof;
	} else static assert (0);
}

enum Normalized;

template isVertexComponent(T) {
	static if(isVectorType!T || isGLNumber!T) {
		enum isVertexComponent = true;
	} else static if (isStaticArray!T && isGLNumber!(ElementType!T) && T.init.length <= MAX_VECTOR_LENGTH) {
		enum isVertexComponent = true;
	} else {
		enum isVertexComponent = false;
	}
}

template VertexComponentSize(T) if (isVertexComponent!T) {
	static if (isVectorType!T) {
		enum VertexComponentSize = vectorSize!T;
	} else static if (isStaticArray!T) {
		enum VertexComponentSize = T.init.length;
	} else static if (isGLNumber!T) {
		enum VertexComponentSize = 1;
	} else static assert (0);
}

template isVertexComponentArray(T) {
	static if (isArray!T && isVertexComponent!(ElementType!T)) {
		enum isVertexComponentArray = true;
	} else {
		enum isVertexComponentArray = false;
	}
}

auto assignVector(T, U)(in U value) if (isVertexComponent!U && isNumeric!T) {
	static if (is(U == struct)) {
		T[value.tupleof.length] retval;

		foreach (size_t i, ref R; retval) {
			R = cast(T)value.tupleof[i];
		}

		return retval;
	} else static if (isStaticArray!U) {
		T[value.length] retval;

		foreach (size_t i, ref R; retval) {
			R = cast(T)value.tupleof[i];
		}

		return retval;
	} else static if (isNumeric!U) {
		T[1] retval;

		retval[0] = cast(T) value;

		return retval;
	} else static assert (0);
}

static assert (isVertexComponent!(const(uint)));
private struct A {
	union {
		struct {
			int b, c;
		}
		int[2] a;
	}
}

private struct B {
	union {
		struct {
			float a, b, c, d;
		}
		struct {
			float x, y, z;
		}
		struct {
			float u, v, t, w;
		}
	}
}

private struct C {
	ubyte x, y;
}

private struct D {
	ulong[4] x;
}

private struct E {
	int a, b;
	float c, d;
}

private struct F {
	union {
		struct {
			uint a, b, c, d;
		}
		float[4] e;
	}
}

private struct G {
	union {
		struct {
			ubyte a, b, c, d, f;
		}
		ubyte[4] e;
	}
}

private struct H {
	double a, b;
}

static assert (isVertexComponent!A);
static assert (isVertexComponent!B);
static assert (isVertexComponent!C);
static assert (isVertexComponent!D);
static assert (!isVertexComponent!E);
static assert (!isVertexComponent!F);
static assert (!isVertexComponent!G);
static assert (!isVertexComponent!H);
static assert(isVertexComponent!int);

template isVertexFormat(T) {
	static if (is(T==struct) && T.init.tupleof.length <= MAX_VERTEX_COMPONENTS 
					&& allSatisfy!(isVertexComponent, FieldTypeTuple!T, ))  {
		enum isVertexFormat = true;
	} else {
		enum isVertexFormat = false;
	}
}

static assert (isMatrix!(short[2][2]));
static assert (isMatrix!(int[4][4]));
static assert (isMatrix!(float[3][3]));
static assert (!isMatrix!(float[3]));
static assert (!isMatrix!(double[3][3]));
static assert (!isMatrix!(char[3][3]));
static assert (!isMatrix!(float[3][3][3]));
static assert (!isMatrix!(float[5][6]));

template isMatrix(T) {
	static if (is(T == struct) && isMatrix!(FieldTypeTuple!(T)[0]) && (T.sizeof == FieldTypeTuple!(T)[0].sizeof)) {
		enum isMatrix = true;
	} else	static if (isStaticArray!T) {
		static if (isStaticArray!(ElementType!T) && isGLNumber!(ElementType!(ElementType!T))) {
			static if (T.init.length == (ElementType!T).init.length) {
				enum isMatrix = true;
			} else {
				enum isMatrix = false;
			}
		} else static if (isGLNumber!(ElementType!T)) {
			static if (T.init.length == 1^^2 || T.init.length == 2^^2 || T.init.length == 3^^2 || T.init.length ==4^^2) {
				enum isMatrix = true;
			} else {
				enum isMatrix = false;
			}
		} else {
			enum isMatrix = false;
		}
	} else static if (is (T == struct)) {
		//allowing static arrays of static arrays in a matrix.
		static if (isStaticArray!(FieldTypeTuple!(T)[0])) {
			static if (isStaticArray!(ElementType!(FieldTypeTuple!(T)[0]))) {
					alias TT = ElementType!(ElementType!(FieldTypeTuple!(T)[0]));
			} else {
				alias TT = ElementType!(FieldTypeTuple!(T)[0]);
			}
		} else {
			alias TT = FieldTypeTuple!(T)[0];
		}
		
		//Currying and adding that second layer of meta-ness.
		enum isTTOrArrayOf(U) = (isOrArrayOf!(T, U) || (isStaticArray!(ElementType!U) && isOrArrayOf!(T, ElementType!U)));
		private bool matchesSquareSize (size_t testVal, size_t limit) {
			for (size_t i = 1; i <= limit; i++) {
				if (testVal == i^^2) return true;
			}

			return false;
		}
		
		//Rules here are:
		//Must be all same data type (and a GLES2.0 compatible number)
		//Must be a square matrix of <= 4 side length.
		//Must be tightly packed.
		static if (isGLNumber!TT &&
						allSatisfy!(isTTOrArrayOf, FieldTypeTuple!T) &&
						matchesSquareSize(T.sizeof, MAX_VECTOR_LENGTH) &&
						T.alignof <= TT.sizeof) {
			enum isMatrix = true;
		} else {
			enum isMatrix = false;
		}


	} else {
		enum isMatrix = false;
	}
}

template MatrixType(T) if (isMatrix!T) {
	static if (isNumeric!T) {
		alias MatrixType = T;
	} else static if (isStaticArray!T) {
		static if (isNumeric!(ElementType!T)) {
			alias MatrixType = ElementType!T;
		} else {
			alias MatrixType = ElementType!(ElementType!T);
		}
	} else static if (is(T == struct)) {
		alias TT = FieldTypeTuple!(T)[0];
		static if (isNumeric!TT) {
			alias MatrixType = TT;
		} else static if (isStaticArray!TT) {
			static if (isNumeric!(ElementType!TT)) {
				alias MatrixType = ElementType!TT;
			} else {
				alias MatrixType = ElementType!(ElementType!TT);
			}
		} else static assert (0);
	} else static assert (0);
}

template MatrixSize(T) if (isMatrix!T) {
	import std.math;
	static if (isNumeric!T) {
		enum MatrixSize = 1;
	} else static if (isStaticArray!T && isNumeric!(ElementType!T)) {
		static assert ((cast(size_t)sqrt(T.init.length) ^^ 2 ) == T.init.length);
		enum MatrixSize = cast(size_t)sqrt(T.init.length);
	} else static if (isStaticArray!T && isStaticArray!(ElementType!T)) {
		static assert (T.init.length == (ElementType!T).init.length);
		enum MatrixSize = T.init.length;
	} else static if (is(T == struct)) {
		enum MatrixSize = cast(size_t)sqrt(cast(real)T.sizeof / MatrixType!(T).sizeof);
		static assert ((MatrixSize ^^ 2)  * MatrixType!(T).sizeof== T.sizeof);
	}
}

auto ref punVector (T) (auto ref T vec) if (isVertexComponent!T) {
	union U{
		T input;
		VectorComponentType!T[vectorSize!T] output;
	}
	
	U* convert = cast(U*)cast(void*)&vec;

	static assert (convert.input.sizeof == convert.output.sizeof);
	
	return convert.output;
}

auto ref punMatrix(T)(auto ref inout T matrix) if (isMatrix!T) {
	union C {
		T input;
		MatrixType!T[MatrixSize!T ^^ 2] output;
	}
	
	auto convert = cast(C*)cast(void*)&matrix;
	static assert (convert.input.sizeof == convert.output.sizeof);

	return convert.output;
}

template isAmbiguousVectorMatrix(T) {
	enum isAmbiguousVectorMatrix = (isVertexComponent!T && isMatrix!T);
}

static assert(isAmbiguousVectorMatrix!(float[4]));
static assert(isAmbiguousVectorMatrix!(int[4]));
static assert(!isAmbiguousVectorMatrix!(int[2][2]));
static assert(!isAmbiguousVectorMatrix!(ubyte[9]));

template containsFloating(T) {
	static if (isFloatingPoint!T) {
		enum containsFloating = true;
	} else static if (isMatrix!T) {
		enum containsFloating = isFloatingPoint!(ElementType!(ElementType!T));
	} else static if (isStaticArray!T) {
		enum containsFloating = isFloatingPoint!(ElementType!T);
	} else static if (isVectorType!T) {
		static if (isFloatingPoint!(FieldTypeTuple!(T)[0])) {
			enum containsFloating = true;
		} else static if (isStaticArray!(FieldTypeTuple!(T)[0]) && isFloatingPoint!(ElementType!(FieldTypeTuple!(T)[0]))) {
			enum containsFloating = true;
		} else {
			enum containsFloating = false;
		}
	} else {
		enum containsFloating = false;
	}
}

template containsIntegral(T) {
	static if (isIntegral!T) {
		enum containsIntegral = true;
	} else static if (isMatrix!T) {
		enum containsIntegral = isIntegral!(ElementType!(ElementType!T));
	} else static if (isStaticArray!T) {
		enum containsIntegral = isIntegral!(ElementType!T);
	} else static if (isVectorType!T) {
		static if (isIntegral!(FieldTypeTuple!(T)[0])) {
			enum containsIntegral = true;
		} else static if (isStaticArray!(FieldTypeTuple!(T)[0]) && isIntegral!(ElementType!(FieldTypeTuple!(T)[0]))) {
			enum containsIntegral = true;
		} else {
			enum containsIntegral = false;
		}
	} else {
		enum containsIntegral = false;
	}
}

template isVertexArrayStruct(T) {
	static if (is(T == struct) && allSatisfy!(isArray, FieldTypeTuple!T) && allSatisfy!(isVertexComponent, staticMap!(ElementType, FieldTypeTuple!T))) {
		enum isVertexArrayStruct = true;
	} else {
		enum isVertexArrayStruct = false;
	}
}

