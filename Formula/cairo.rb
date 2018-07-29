class Cairo < Formula
  desc "Vector graphics library with cross-device output support"
  homepage "https://cairographics.org/"
  url "https://www.cairographics.org/snapshots/cairo-1.15.12.tar.xz"
  sha256 "7623081b94548a47ee6839a7312af34e9322997806948b6eec421a8c6d0594c9"

  head do
    url "https://anongit.freedesktop.org/git/cairo", :using => :git
    depends_on "automake" => :build
    depends_on "autoconf" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "freetype"
  depends_on "fontconfig"
  depends_on "libpng"
  depends_on "pixman"
  depends_on "glib"

  # Patch OpenGL header for macOS
  patch :p0, <<~EOS
diff --git a/configure.ac b/configure.ac
index 5ee63a693..ae790d9fb 100644
--- a/configure.ac
+++ b/configure.ac
@@ -344,11 +344,11 @@ CAIRO_ENABLE_FUNCTIONS(png, PNG, yes, [
     use_png=yes
   fi

-  if test "x$use_png" = "xyes" ; then
+  if test "x$use_png" = "xyes" ; then
     PKG_CHECK_MODULES(png, $png_REQUIRES, , : )
   else
     AC_MSG_WARN([Could not find libpng in the pkg-config search path])
-  fi
+  fi
 ])

 dnl ===========================================================================
@@ -356,7 +356,7 @@ CAIRO_ENABLE_SURFACE_BACKEND(gl, OpenGL, no, [
   gl_REQUIRES="gl"
   PKG_CHECK_MODULES(gl, $gl_REQUIRES,, [
 	  dnl Fallback to searching for headers
-	  AC_CHECK_HEADER(GL/gl.h,, [use_gl="no (gl.pc nor OpenGL headers not found)"])
+	  AC_CHECK_HEADER(OpenGL/gl.h,, [use_gl="no (gl.pc nor OpenGL headers not found)"])
 	  if test "x$use_gl" = "xyes"; then
 	      gl_NONPKGCONFIG_CFLAGS=
 	      gl_NONPKGCONFIG_LIBS="-lGL"
@@ -536,11 +536,11 @@ CAIRO_ENABLE_FONT_BACKEND(ft, FreeType, auto, [
     PKG_CHECK_MODULES(FREETYPE, freetype2 >= $FREETYPE_MIN_VERSION,
                       [freetype_pkgconfig=yes],
 		      [freetype_pkgconfig=no])
-
+
     if test "x$freetype_pkgconfig" = "xyes"; then
       ft_REQUIRES="freetype2 >= $FREETYPE_MIN_VERSION $ft_REQUIRES"
     else
-
+
       if test -z "$FREETYPE_CONFIG"; then
         AC_PATH_PROG(FREETYPE_CONFIG, freetype-config, no)
       fi
diff --git a/src/cairo-gl-private.h b/src/cairo-gl-private.h
index f02a58763..85a1e0512 100644
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
  EOS

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
