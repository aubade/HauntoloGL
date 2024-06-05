/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.window;

import bindbc.sdl;

import hauntologl.gl.config;
import hauntologl.gl.shaders;
import hauntologl.gl.vertices;

class Window {
	public:
	enum Flags {
		Fullscreen = SDL_WINDOW_FULLSCREEN,
		Shown= SDL_WINDOW_SHOWN,
		Hidden = SDL_WINDOW_HIDDEN,
		Borderless = SDL_WINDOW_BORDERLESS ,
		Resizable = SDL_WINDOW_RESIZABLE,
		Minimized = SDL_WINDOW_MINIMIZED,
		Maximized = SDL_WINDOW_MAXIMIZED,
		Grabbed = SDL_WINDOW_INPUT_GRABBED,
		InputFocus = SDL_WINDOW_INPUT_FOCUS,
		MouseFocus = SDL_WINDOW_MOUSE_FOCUS,
		FullscreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP,
		Foreign = SDL_WINDOW_FOREIGN,
		HighDPI = SDL_WINDOW_ALLOW_HIGHDPI,
		Capture = SDL_WINDOW_MOUSE_CAPTURE,
		AlwaysOnTop = SDL_WINDOW_ALWAYS_ON_TOP,
		SkipTaskbar = SDL_WINDOW_SKIP_TASKBAR,
		Utility = SDL_WINDOW_UTILITY,
		Tooltip = SDL_WINDOW_TOOLTIP,
		PopupMenu = SDL_WINDOW_POPUP_MENU
	}


	this(int width, int height, const(char)[] name = defaultname,  int flags = SDL_WINDOW_SHOWN) {
		import std.stdio;
		ensureInit();
		writeln("GL Initialized");

		flags |= SDL_WINDOW_OPENGL;

		handle_ = SDL_CreateWindow(name.ptr, 0, 0, width, height,  flags);
		assert(handle_);
		writeln("SDL window created");

		version (GLES_20) {
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
		} else version (GL_20) {
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
		} else version (GLES_32) {
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
		} else version (GL_32) {
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
		}

		//SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		//SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
		//SDL_GL_SetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1);

		ensureGL();
		writeln("Creating context");
		context_ = SDL_GL_CreateContext(handle_);
		writeln("Context created");
		assert(context_);
	}

	~this() {
		SDL_GL_DeleteContext(context_);
		SDL_DestroyWindow(handle_);

	}

	void makeCurrent() {
		SDL_GL_MakeCurrent(handle_, context_);
	}

	void swap() {
		SDL_GL_SwapWindow(handle_);
	}

	alias handle_ this;

	private:
	version (GL_20) {
		static immutable string defaultname = "HauntoloGL";
	} else version (GLES_20) {
		static immutable string defaultname = "HauntoloGL ES";
	}

	shared static bool hasInit_ = false;

	static void ensureInit() {
		if (hasInit_ ) return;
		assert(!SDL_InitSubSystem(SDL_INIT_VIDEO));

		hasInit_ = true;
	}
	SDL_Window* handle_;
	SDL_GLContext context_;
}