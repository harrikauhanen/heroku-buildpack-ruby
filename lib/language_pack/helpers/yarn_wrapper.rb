class LanguagePack::Helpers::YarnWrapper
  include LanguagePack::ShellHelpers

  class PackageFileParseError < BuildpackError
    def initialize(error)
      msg = "There was an error parsing your package.json, we cannot continue\n"
      msg << error
      super msg
    end
  end

  VENDOR_DIR_PATH      = './vendor'

  def initialize
    @vendor_dir_path =  ENV['VENDOR_DIR_PATH'] || VENDOR_DIR_PATH
    @vendor_path = Pathname.new(@vendor_dir_path).realpath
    @yarn_fetcher = LanguagePack::Fetcher.new("https://yarnpkg.com/downloads/")
    @node_fetcher = LanguagePack::Fetcher.new("https://nodejs.org/dist/")
  end

  def install_node_modules_and_dependencies
    topic "Testing for yarn config"
    FileUtils.chdir @vendor_path do
      topic `pwd`
      topic `ls`
      if node_app?
        topic "yarn config detected"
        instrument "webpacker.setup" do
          install_node
          install_yarn
          install_packages
        end
      end
    end
  end

  def node_app?
    FileUtils.chdir @vendor_path do
      return yarn_lock_file_path
    end
  end

  private

  def install_yarn
    instrument "yarn.download" do
      topic "installing yarn #{yarn_version}"
      @yarn_fetcher.fetch_untar("#{yarn_version}/yarn-v#{yarn_version}.tar.gz", "dist/")
      FileUtils.cp_r("dist/.", "./yarn")
      FileUtils.rm_rf("dist")
    end
  end

  def install_node
    instrument "node.download" do
      untared_folder = "node-v#{node_version}-linux-x64"
      topic "installing #{untared_folder}"
      @yarn_fetcher.fetch_untar("v#{node_version}/#{untared_folder}.tar.gz", "#{untared_folder}/bin")
      FileUtils.mkdir("./node")
      FileUtils.cp_r("#{untared_folder}/.", "./node")
      FileUtils.rm_rf(untared_folder)
    end
  end

  def install_packages
    instrument "yarn.install" do
      topic "installing node modules"
      exec "../bin/yarn install"
      topic "installing node packages done"
    end
  end

  def yarn_version
    @yarn_version ||= open("https://semver.herokuapp.com/yarn/resolve/#{provided_node_version}")
  end

  def node_version
    @node_version ||= open("https://semver.herokuapp.com/node/resolve/#{provided_node_version}")
  end

  def package_dot_json_content
    return @package_dot_json_content if @package_dot_json_content
    return {} unless package_dot_json_file_path
    json = File.read('file-name-to-be-read.json')
    @package_dot_json_content = JSON.parse(json)
  end

  def engine_config
    @engine_config ||= package_dot_json_content.fetch('engines', {})
  end

  def provided_node_version
    engine_config['node']
  end

  def provided_yarn_version
    engine_config['yarn']
  end

  def yarn_lock_file_path
    Dir["yarn.lock"].first
  end

  def package_dot_json_file_path
    Dir["package.json"].first
  end

end
