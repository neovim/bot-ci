# Send a non-authenticated request to the Travis API.
# ${1}: API endpoint.
send_travis_api_request() {
  local endpoint="${1}"

  curl -H "Accept: application/vnd.travis-ci.2+json" \
    -X GET \
    https://api.travis-ci.org/${endpoint} \
    2>/dev/null
}
