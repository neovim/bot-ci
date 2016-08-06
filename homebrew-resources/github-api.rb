require "base64"
require "unirest"

module GithubAPI extend self
  def make_request_header
    headers = {
      "User-Agent" => "neovim/bot-ci",
      "Accept" => "application/vnd.github.v3+json",
      "Content-Type" => "application/json",
    }
    headers["Authorization"] = "token #{ENV["GH_TOKEN"]}" if ENV["GH_TOKEN"]
    headers
  end

  def check_response_error response, expected_code
    unless response.code == expected_code
      raise "HTTP #{response.code} #{response.body["message"]} (expected #{expected_code})"
    end
  end

  def list_branches repo
    response = Unirest.get "https://api.github.com/repos/#{repo}/branches",
                           headers: make_request_header
    check_response_error response, 200
    response.body
  end

  def get_head_sha repo, branch
    response = Unirest.get "https://api.github.com/repos/#{repo}/git/refs/heads/#{branch}",
                           headers: make_request_header
    check_response_error response, 200
    response.body["object"]["sha"]
  end

  def create_new_branch repo, name
    response = Unirest.post "https://api.github.com/repos/#{repo}/git/refs",
                            headers: make_request_header,
                            parameters: {
                              "ref" => "refs/heads/#{name}",
                              "sha" => get_head_sha(repo, "master"),
                            }.to_json
    check_response_error response, 201
    response.body
  end

  def get_blob_sha repo, branch, path
    response = Unirest.get "https://api.github.com/repos/#{repo}/contents/#{path}",
                           headers: make_request_header,
                           parameters: { "ref" => "ref/heads/#{branch}", }.to_json
    check_response_error response, 200
    response.body["sha"]
  end

  def update_file repo, branch, path, message, content
    response = Unirest.put "https://api.github.com/repos/#{repo}/contents/#{path}",
                           headers: make_request_header,
                           parameters: {
                             "message" => message,
                             "content" => Base64.encode64(content),
                             "sha" => get_blob_sha(repo, branch, path),
                             "branch" => branch,
                           }.to_json
    check_response_error response, 200
    response.body
  end

  def create_pull_request repo, branch, title, body
    response = Unirest.post "https://api.github.com/repos/#{repo}/pulls",
                            headers: make_request_header,
                            parameters: {
                              "title" => title,
                              "body" => body,
                              "head" => "#{repo.split("/")[0]}:#{branch}",
                              "base" => "master",
                            }.to_json
    check_response_error response, 201
    response.body
  end
end
