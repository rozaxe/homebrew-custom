class Cairo < Formula
  desc "Vector graphics library with cross-device output support"
  homepage "https://cairographics.org/"

  stable do
    url "https://www.cairographics.org/snapshots/cairo-1.15.12.tar.xz"
    sha256 "7623081b94548a47ee6839a7312af34e9322997806948b6eec421a8c6d0594c9"

    # Patch OpenGL header for macOS
    patch :DATA
    patch :p0, :DATA
  end

  #head do
  #  url "https://anongit.freedesktop.org/git/cairo", :using => :git
  #  depends_on "automake" => :build
  #  depends_on "autoconf" => :build
  #  depends_on "libtool" => :build
  #end

  depends_on "pkg-config" => :build
  depends_on "freetype"
  depends_on "fontconfig"
  depends_on "libpng"
  depends_on "pixman"
  depends_on "glib"

  def install
    if build.head?
      ENV["NOCONFIGURE"] = "1"
      system "./autogen.sh"
    end

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-gobject=yes",
                          "--enable-gl=yes",
                          "--enable-svg=yes",
                          "--enable-tee=yes",
                          "--enable-quartz-image",
                          "--enable-xcb=no",
                          "--enable-xlib=no",
                          "--enable-xlib-xrender=no"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <cairo.h>

      int main(int argc, char *argv[]) {

        cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 600, 400);
        cairo_t *context = cairo_create(surface);

        return 0;
      }
    EOS
    fontconfig = Formula["fontconfig"]
    freetype = Formula["freetype"]
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    libpng = Formula["libpng"]
    pixman = Formula["pixman"]
    flags = %W[
      -I#{fontconfig.opt_include}
      -I#{freetype.opt_include}/freetype2
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{include}/cairo
      -I#{libpng.opt_include}/libpng16
      -I#{pixman.opt_include}/pixman-1
      -L#{lib}
      -lcairo
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end

__END__
--- a/configure.ac
+++ b/configure.ac
@@ -356,7 +356,7 @@ CAIRO_ENABLE_SURFACE_BACKEND(gl, OpenGL, no, [
   gl_REQUIRES="gl"
   PKG_CHECK_MODULES(gl, $gl_REQUIRES,, [
 	  dnl Fallback to searching for headers
-	  AC_CHECK_HEADER(GL/gl.h,, [use_gl="no (gl.pc nor OpenGL headers not found)"])
+	  AC_CHECK_HEADER(OpenGL/gl.h,, [use_gl="no (gl.pc nor OpenGL headers not found)"])
 	  if test "x$use_gl" = "xyes"; then
 	      gl_NONPKGCONFIG_CFLAGS=
 	      gl_NONPKGCONFIG_LIBS="-lGL"
--- a/src/cairo-gl-private.h
+++ b/src/cairo-gl-private.h
@@ -67,8 +67,8 @@
 #include <GLES2/gl2.h>
 #include <GLES2/gl2ext.h>
 #elif CAIRO_HAS_GL_SURFACE
-#include <GL/gl.h>
-#include <GL/glext.h>
+#include <OpenGL/gl.h>
+#include <OpenGL/glext.h>
 #endif

 #include "cairo-gl-ext-def-private.h"
