class Ocrmypdf < Formula
  include Language::Python::Virtualenv

  desc "Adds an OCR text layer to scanned PDF files"
  homepage "https://github.com/jbarlow83/OCRmyPDF"
  url "https://files.pythonhosted.org/packages/bd/62/81cb1e337863081825c1f89b6d1648151d71b26b4ef82afdb7017409499a/ocrmypdf-6.2.1.tar.gz"
  sha256 "9b615492f7fc6bec0e49483d89378d8647de1b61c701e060c9bd11a686c9b256"
  revision 1

  bottle do
    cellar :any
    sha256 "2a6700bf8a0693310ebb56fcd151b6e2c9037554149dd069ecfdd1f79b3a639a" => :high_sierra
    sha256 "e8aa0dad49cb9061af519091aeac025ff8d234a87fc54b9ba39a479af5fa3ffd" => :sierra
    sha256 "ed3976367dbde22692e846e9b2c9426415513f3219573f43f32ee1f2d73fb90c" => :el_capitan
  end

  depends_on "mupdf-tools" => :build # PyMuPDF statically links to libmupdf.a
  depends_on "pkg-config" => :build
  depends_on "freetype"
  depends_on "ghostscript"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "python"
  depends_on "qpdf"
  depends_on "tesseract"
  depends_on "unpaper"

  resource "cffi" do
    url "https://files.pythonhosted.org/packages/e7/a7/4cd50e57cc6f436f1cc3a7e8fa700ff9b8b4d471620629074913e3735fb2/cffi-1.11.5.tar.gz"
    sha256 "e90f17980e6ab0f3c2f3730e56d1fe9bcba1891eeea58966e89d352492cc74f4"
  end

  resource "defusedxml" do
    url "https://files.pythonhosted.org/packages/74/ba/4ba4e89e21b5a2e267d80736ea674609a0a33cc4435a6d748ef04f1f9374/defusedxml-0.5.0.tar.gz"
    sha256 "24d7f2f94f7f3cb6061acb215685e5125fbcdc40a857eff9de22518820b0a4f4"
  end

  resource "img2pdf" do
    url "https://files.pythonhosted.org/packages/7e/a2/4f06081f674920be757d894b4bab874e6a3b5227e730cb7618430b366e69/img2pdf-0.2.4.tar.gz"
    sha256 "140b70fa3a3bfb54e92947818cee01483a4f1492b5d1d02b0f649257f5ffc9ae"
  end

  resource "Pillow" do
    url "https://files.pythonhosted.org/packages/0f/57/25be1a4c2d487942c3ed360f6eee7f41c5b9196a09ca71c54d1a33c968d9/Pillow-5.0.0.tar.gz"
    sha256 "12f29d6c23424f704c66b5b68c02fe0b571504459605cfe36ab8158359b0e1bb"
  end

  resource "pycparser" do
    url "https://files.pythonhosted.org/packages/8c/2d/aad7f16146f4197a11f8e91fb81df177adcc2073d36a17b1491fd09df6ed/pycparser-2.18.tar.gz"
    sha256 "99a8ca03e29851d96616ad0404b4aad7d9ee16f25c9f9708a11faf2810f7b226"
  end

  resource "PyMuPDF" do
    url "https://files.pythonhosted.org/packages/f2/8d/d34d13d7ebc4771bdc37149020830c7bce331e7c7515632c3c0ef362bfa0/PyMuPDF-1.13.11.tar.gz"
    sha256 "28e3a5d42211accc30b18e6da4b50962c2e682d8626a2a80b638e17bfa6fa46c"
  end

  resource "PyPDF2" do
    url "https://files.pythonhosted.org/packages/b4/01/68fcc0d43daf4c6bdbc6b33cc3f77bda531c86b174cac56ef0ffdb96faab/PyPDF2-1.26.0.tar.gz"
    sha256 "e28f902f2f0a1603ea95ebe21dff311ef09be3d0f0ef29a3e44a932729564385"
  end

  resource "reportlab" do
    url "https://files.pythonhosted.org/packages/87/f9/53b34c58d3735a6df7d5c542bf4de60d699cfa6035e113ca08b3ecdcca3f/reportlab-3.4.0.tar.gz"
    sha256 "5beaf35e59dfd5ebd814fdefd76908292e818c982bd7332b5d347dfd2f01c343"
  end

  resource "ruffus" do
    url "https://files.pythonhosted.org/packages/97/fe/12445c6793350ab5dbf76cb87a122b9e9aab9a9040a2801004806d985216/ruffus-2.6.3.tar.gz"
    sha256 "d78728d802013d91d15e5e939554dabce196967734850fa44634dce47e3e5061"

    # Python 3.7 compat
    patch :DATA
  end

  def install
    venv = virtualenv_create(libexec, "python3")

    resource("Pillow").stage do
      inreplace "setup.py" do |s|
        sdkprefix = MacOS::CLT.installed? ? "" : MacOS.sdk_path
        s.gsub! "openjpeg.h", "probably_not_a_header_called_this_eh.h"
        s.gsub! "ZLIB_ROOT = None", "ZLIB_ROOT = ('#{sdkprefix}/usr/lib', '#{sdkprefix}/usr/include')"
        s.gsub! "JPEG_ROOT = None", "JPEG_ROOT = ('#{Formula["jpeg"].opt_prefix}/lib', '#{Formula["jpeg"].opt_prefix}/include')"
        s.gsub! "FREETYPE_ROOT = None", "FREETYPE_ROOT = ('#{Formula["freetype"].opt_prefix}/lib', '#{Formula["freetype"].opt_prefix}/include')"
      end

      # avoid triggering "helpful" distutils code that doesn't recognize Xcode 7 .tbd stubs
      ENV.append "CFLAGS", "-I#{MacOS.sdk_path}/System/Library/Frameworks/Tk.framework/Versions/8.5/Headers" unless MacOS::CLT.installed?
      venv.pip_install Pathname.pwd
    end

    res = resources.map(&:name).to_set - ["Pillow"]

    res.each do |r|
      venv.pip_install resource(r)
    end

    venv.pip_install_and_link buildpath
  end

  test do
    # Since we use Python 3, we require a UTF-8 locale
    ENV["LC_ALL"] = "en_US.UTF-8"

    system "#{bin}/ocrmypdf", "-f", "-q", "--deskew",
                              test_fixtures("test.pdf"), "ocr.pdf"
    assert_predicate testpath/"ocr.pdf", :exist?
  end
end

__END__
diff --git a/ruffus/task.py b/ruffus/task.py
index 18d1d98..9337250 100644
--- a/ruffus/task.py
+++ b/ruffus/task.py
@@ -711,8 +711,7 @@ t_job_result = namedtuple('t_job_result',
                           'return_value '
                           'exception '
                           'params '
-                          'unglobbed_params ',
-                          verbose=0)
+                          'unglobbed_params ')
 
 
 # _____________________________________________________________________________
@@ -5942,7 +5941,7 @@ def pipeline_run(target_tasks=[],
 #       default in python 2.5 and greater
 #   N.B. File modify times / stat values have 1 second precision for many file
 #       systems and may not be accurate to boot, especially over the network.
-os.stat_float_times(True)
+# os.stat_float_times(True)
 
 
 if __name__ == '__main__':
