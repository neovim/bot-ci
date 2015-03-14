require "pathname"

# Load Homebrew Library.
HOMEBREW_LIBRARY_PATH = Bundler.with_clean_env { Pathname.new(`brew --prefix`.strip)/"Library/Homebrew" }
abort "Fail to load Homebrew" unless HOMEBREW_LIBRARY_PATH.exist?
$:.unshift HOMEBREW_LIBRARY_PATH
require "global"
require "formula"

ohai "Tap neovim/neovim"
Bundler.with_clean_env do
  system "brew", "tap", "neovim/neovim"
  system "brew", "tap", "--repair"
  system "brew", "update"
end

ohai "Extract resources info from formula"
formula = Formula["neovim"]
formula_res_info = {};
formula.resources.map do |r|
  checksum = r.checksum
  formula_res_info[r.name] = { :url => r.url, checksum.hash_type => checksum.hexdigest }
end

ohai "Download neovim/third-party/CMakeLists.txt"
cmake = `curl -L https://github.com/neovim/neovim/raw/master/third-party/CMakeLists.txt`
abort "Fail to download CMakeLists.txt" unless $?.success?

ohai "Extract resources info from CMakeLists.txt"
cmake_res_info = {}
cmake.scan(/([A-Z]+)_URL ([^\)]+)/) do |m|
  name = m[0].downcase
  url = m[1]
  cmake_res_info[name] ||= {}
  cmake_res_info[name][:url] = url
end
cmake.scan(/([A-Z]+)_SHA256 ([^\)]+)/) do |m|
  name = m[0].downcase
  sha256 = m[1]
  cmake_res_info[name] ||= {}
  cmake_res_info[name][:sha256] = sha256
end

ohai "Compare resources between formula and CMakeLists.txt"
if cmake_res_info == formula_res_info
  puts "Resources are consistent"
  exit 0
end

ohai "Create new formula"
res_code = cmake_res_info.map do |name, info|
  <<-EOS
  resource "#{name}" do
    url "#{info[:url]}"
    sha256 "#{info[:sha256]}"
  end

  EOS
end.join
formula_code = File.read(formula.path)
formula_code.gsub! /(^ {2}resource "\w+" do(.|\n)+?^ {2}end\n+)+/m, res_code

ohai "Upload formula"
require_relative "./github-api.rb"
repo = "neovim/homebrew-neovim"
branch = "formula-resource-update"
path = "Formula/neovim.rb"
message = "Formula Resource Update"
report = <<-EOS.undent
 ADD: #{cmake_res_info.reject{ |k, v| formula_res_info.include? k }.keys.join(", ")}
 DELETE: #{formula_res_info.reject{ |k, v| cmake_res_info.include? k }.keys.join(", ")}
 MODIFY: #{cmake_res_info.select { |k, v| formula_res_info[k] != v }.keys.join(", ")}
EOS

unless GithubAPI.list_branches(repo).find { |b| b["name"] == branch }.nil?
  puts "Found existed branch(#{branch}). Skip updating."
  exit 0
end

GithubAPI.create_new_branch repo, branch
GithubAPI.update_file repo, branch, path, message + "\n" + report, formula_code
response = GithubAPI.create_pull_request repo, branch, message, report
puts response["html_url"]
