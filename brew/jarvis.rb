class Jarvis < Formula
  desc "Self-contained personal AI assistant (OpenCode + agents inside)"
  homepage "https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode"
  url "https://github.com/davisoliveira1520-cmd/fullstack-agent-opencode/releases/download/v1.0.0/jarvis.zip"
  sha256 "a84ea08d15b5d87a7ce4b3c4a8a731359b41a0a487351e565b1e1ccfc1657977"
  license "AGPL-3.0-or-later"

  depends_on "bash"

  def install
    bin.install Dir["jarvis.bat"] if OS.windows?
    bin.install "jarvis.sh"
  end

  def caveats
    <<~EOS
      Run Jarvis with:
        jarvis.sh
      (Windows: open the jarvis.bat in #{bin})
    EOS
  end

  test do
    assert_predicate bin/"jarvis.sh", :exist?
  end
end