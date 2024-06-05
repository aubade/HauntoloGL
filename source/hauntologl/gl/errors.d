/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.gl.errors;

import hauntologl.gl.config;
import std.exception;

class GLError:Exception {
	enum Code:GLenum {
		NoError = GL_NO_ERROR,
		InvalidEnum = GL_INVALID_ENUM,
		InvalidValue = GL_INVALID_VALUE,
		InvalidOperation = GL_INVALID_OPERATION,
		InvalidFramebufferOperation = GL_INVALID_FRAMEBUFFER_OPERATION,
		OutOfMemory = GL_OUT_OF_MEMORY,
		CompilerError,
		LinkerError
	}

	Code code;

	this (Code errorCode, string description, string filen = __FILE__, size_t linen = __LINE__)  {
		import std.conv;
		super(to!string(to!string(errorCode) ~ " - " ~ description), filen, linen);

		code = errorCode;
	}
}

void checkError(string file = __FILE__, size_t line = __LINE__) {
	auto code = cast(GLError.Code)glGetError();
	switch (code) {
		case GLError.Code.InvalidEnum:
			throw new GLError(code, "An unacceptable value is specified for an enumerated argument.", file, line);
		case GLError.Code.InvalidValue:
			throw new GLError(code, "A numeric argument is out of range. ", file, line);
		case GLError.Code.InvalidOperation:
			throw new GLError(code, "The specified operation is not allowed in the current state. ", file, line);
		case GLError.Code.InvalidFramebufferOperation:
			throw new GLError(code, "The command is trying to render to or read from the framebuffer while the currently bound framebuffer is not framebuffer complete (i.e. the return value from glCheckFramebufferStatus is not GL_FRAMEBUFFER_COMPLETE).", file, line);
		case GLError.Code.OutOfMemory:
			throw new GLError(code, " There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded. ", file, line);
		case GLError.Code.NoError:
		default:
			return;
	}
}