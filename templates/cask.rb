cask "@NAME@" do
  version "@VERSION@"
  sha256 "@SHA@"

  url "https://github.com/@REPO@/releases/download/v#{version}/@APP@.zip"
  name "@APP@"
  desc "@DESC@"
  homepage "https://github.com/@REPO@"

  depends_on macos: :ventura

  app "@APP@.app"

  zap trash: "~/Library/Application Support/@APP@"
end
