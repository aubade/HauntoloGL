module hauntologl.gl.framebuffers;

import hauntologl.gl.textures;
import hauntologl.gl.config;

class RenderBuffer {
	public:
	enum Parameter:GLenum {
		Width = GL_RENDERBUFFER_WIDTH,
		Height = GL_RENDERBUFFER_HEIGHT,
		Format = GL_RENDERBUFFER_INTERNAL_FORMAT,
		RedSize = GL_RENDERBUFFER_RED_SIZE,
		GreenSize = GL_RENDERBUFFER_GREEN_SIZE,
		BlueSize = GL_RENDERBUFFER_BLUE_SIZE,
		AlphaSize = GL_RENDERBUFFER_ALPHA_SIZE,
		DepthSize = GL_RENDERBUFFER_DEPTH_SIZE,
		StencilSize = GL_RENDERBUFFER_STENCIL_SIZE
	}

	this() {
		glGenRenderbuffers(1, &handle_);
		version (GLDebug) checkError();
	}

	~this() {
		glDeleteRenderbuffers (1, &handle_);
		version (GLDebug) checkError();
	}

	this() const {
		GLuint temphandle;
		glGenRenderbuffers(1, &temphandle);
		handle_ = temphandle;
		version (GLDebug) checkError();
	}

	GLint getParameter(GLenum param) {
		GLint retval;
		glGetRenderbufferParameteriv(GL_RENDERBUFFER, param, &retval);
		version (GLDebug) checkError();
		return retval;
	}

	void size(GLsizei width, GLsizei height, Texture.Format format) {
		this.bind();
		glRenderbufferStorage(GL_RENDERBUFFER, format, width, height);
		version (GLDebug) checkError();
	}

	private:
		GLuint handle_;
}

void bind(const(RenderBuffer) buffer) {
		glBindRenderbuffer(GL_RENDERBUFFER, buffer?buffer.handle_:0);
		version (GLDebug) checkError();
}


class FBO {
	enum Attachment:GLenum {
		Color = GL_COLOR_ATTACHMENT0,
		Depth = GL_DEPTH_ATTACHMENT,
		Stencil = GL_STENCIL_ATTACHMENT
	}
	enum Parameter:GLenum {
		ObjecType = GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
		ObjectName = GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
		TextureLevel = GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL,
		TextureCubeMapFace = GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE
	}
	enum ObjectType:GLenum {
		None = GL_NONE,
		RenderBuffer = GL_RENDERBUFFER,
		Texture = GL_TEXTURE
	}
	version( GLES_20) enum Status {
		Complete = GL_FRAMEBUFFER_COMPLETE,
		IncompleteAttachment = GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT,
		IncompleteDimension = GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS,
		MissingAttachment = GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT,
		Unsupported = GL_FRAMEBUFFER_UNSUPPORTED,
		IncompleteDrawBuffer = -1,
		IncompleteReadBuffer = -1,
		IncompleteMultisample = -1,
		Undefined = -1
	} else version (GL_20)  enum Status {
		Complete = GL_FRAMEBUFFER_COMPLETE,
		IncompleteAttachment = GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT,
		MissingAttachment = GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT,
		IncompleteDrawBuffer = GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER,
		IncompleteReadBuffer = GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER,
		IncompleteMultisample = GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE,
		Undefined = GL_FRAMEBUFFER_UNDEFINED,
		Unsupported = GL_FRAMEBUFFER_UNSUPPORTED,
		IncompleteDimension = -1,
}

	this() {
		version (GLES_20) {} else {
			assert(hasARBFramebufferObject());
		}

		glGenFramebuffers(1, &handle_);
		version (GLDebug) checkError();
	}

	void attach(RenderBuffer b, Attachment point = Attachment.Color ) {
		glFramebufferRenderbuffer(handle_, point, GL_RENDERBUFFER, b.handle_);
		version (GLDebug) checkError();
	}

	void attach (Texture t, Attachment point, Texture.Type type, GLint mipmap = 0) {
		glFramebufferTexture2D(handle_, point, type, t.handle_, mipmap);
		version (GLDebug) checkError();
	}

	auto getAttachmentParameter (Attachment point, Parameter param) {
		GLint retval;

		glGetFramebufferAttachmentParameteriv (handle_, point, param, &retval);
		version (GLDebug) checkError();

		return retval;
	}

	auto status() const @nogc {
		return glCheckFramebufferStatus(handle_);
	}

	this() const {
		version (GLES_20) {} else {
			assert(hasARBFramebufferObject());
		}
		
		GLuint temphandle;
		glGenFramebuffers(1, &temphandle);
		version (GLDebug) checkError();
		handle_ = temphandle;
	}

	~this() {
		glDeleteFramebuffers (1, &handle_);
		version (GLDebug) checkError();
	}
	private:
		GLuint handle_;
} 
void readPixels(const(FBO) buffer, void[] destBuffer, GLint x, GLint y, GLsizei width, GLsizei height, Texture.Format format, Texture.Size size) {
	assert(destBuffer.length >= width * height * Texture.pixelSize(format, size));		
	buffer.bind();

	glReadPixels(x, y, width, height, format, size, destBuffer.ptr);
	version (GLDebug) checkError();
}

void bind(const(FBO) buffer) {
	glBindFramebuffer(GL_FRAMEBUFFER, buffer?buffer.handle_:0);
	version (GLDebug) checkError();
}
