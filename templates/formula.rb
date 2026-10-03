class @CLASS@ < Formula
  desc "@DESC@"
  homepage "https://github.com/@REPO@"
  url "@URL@"
  sha256 "@SHA@"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"@NAME@", "--version"
  end
end
