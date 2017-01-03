require 'json'
require 'open-uri'
require 'uri'

class LanguagePack::Helpers::YarnWrapper
  include LanguagePack::ShellHelpers
  include YarnConfigFileHelper

  VENDOR_DIR_PATH      = './vendor'

  def initialize
    vendor_dir_path =  ENV['VENDOR_DIR_PATH'] || VENDOR_DIR_PATH
    @vendor_path = Pathname.new(vendor_dir_path).realpath
  end

  def install_node_modules_and_dependencies
    FileUtils.chdir @vendor_path do
      if node_app?
        topic "yarn.lock file detected"
        install_node
        install_yarn
        install_packages
      end
    end
  end

  def node_app?
    FileUtils.chdir @vendor_path do
      return yarn_lock_file && package_file
    end
  end

  private

  def install_yarn
    YarnInstaller.new.perform
  end

  def install_node
    NodeInstaller.new.perform
  end

  def install_packages
    run! "../bin/yarn install"
  end

  class VersionResolver

    def resolve_node(provided_version)
      open("https://semver.herokuapp.com/node/resolve/#{provided_version}")
    end

    def resolve_yarn(provided_version)
      open("https://semver.herokuapp.com/yarn/resolve/#{provided_version}")
    end

    private

    def open uri
      super(URI.escape(uri)).read
    end

  end

  module YarnConfigFileHelper

    def parsed_package_file
      @parsed_package_file ||= begin
        json = File.read(package_file)
        JSON.parse(json)
      end
    end

    def engine_config
      @engine_config ||= parsed_package_file.fetch('engines', {})
    end

    def node_version
      engine_config['node']
    end

    def yarn_version
      engine_config['yarn']
    end

    def yarn_lock_file
      Dir["yarn.lock"].first
    end

    def package_file
      Dir["package.json"].first
    end
  end

  class NodeInstaller
    include YarnConfigFileHelper

    def initialize
      @node_fetcher = LanguagePack::Fetcher.new("https://nodejs.org/dist/")
    end

    def perform
      topic "installing #{binary_name}"
      @node_fetcher.fetch_untar(binary_path, "#{binary_name}/bin")
      FileUtils.cp_r("#{binary_name}/.", "./node")
      FileUtils.rm_rf(binary_name)
    end

    private

    def version
      @version ||= VersionResolver.new.resolve_node(node_version)
    end

    def binary_name
      @binary_name ||= "node-v#{version}-linux-x64"
    end

    def binary_path
      "v#{version}/#{binary_name}.tar.gz"
    end

  end

  class YarnInstaller
    include YarnConfigFileHelper

    def initialize
      @yarn_fetcher = LanguagePack::Fetcher.new("https://yarnpkg.com/downloads/")
    end

    def perform
      topic "installing yarn v#{version}"
      @yarn_fetcher.fetch_untar(binary_path, "dist/")
      FileUtils.cp_r("dist/.", "./yarn")
      FileUtils.rm_rf("dist")
    end

    private

    def version
      @version ||= VersionResolver.new.resolve_yarn(yarn_version)
    end

    def binary_path
      "#{version}/yarn-v#{version}.tar.gz"
    end

  end

end
