class LanguagePack::YarnInstaller

  YARN_SOURCE_URL = "https://yarnpkg.com/"

  def initialize(build_path, cache_path)
    @fetcher = LanguagePack::Fetcher.new(YARN_SOURCE_URL)
    @node_fetcher = LanguagePack::Fetcher.new("https://nodejs.org/dist/v7.3.0/node-v7.3.0-linux-x64.tar.gz")
    @build_path = build_path
    puts "build path = #{@build_path}"
  end

  def version
    "latest.tar.gz"
  end

  def binary_path
    if @legacy
      LEGACY_BINARY_PATH
    else
      MODERN_BINARY_PATH
    end
  end

  def install
    install_node
    @fetcher.fetch_untar(version, "dist/bin/")
    FileUtils.cp_r("dist/bin/.", ".")
    FileUtils.rm_rf("dist")
  end

  def install_node
    @node_fetcher.fetch_untar("", "node-v7.3.0-linux-x64/bin")
    FileUtils.cp_r("node-v7.3.0-linux-x64/bin/.", ".")
    FileUtils.rm_rf("node-v7.3.0-linux-x64")
  end

end
