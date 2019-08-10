# Reference:
#   GitHub API REPL: https://developer.github.com/v4/explorer/
#   Python GQL client: https://github.com/graphql-python/gql
#
# Requirements:
#   $ pip install gql pytest
#

import gql
from gql.transport.requests import RequestsHTTPTransport

# GH API token: marvim "bot-pr"
token = 'xxx'

def get_recent_pr_comments(repoowner, reponame):
  client = gql.Client(
    # retries=1,
    transport=RequestsHTTPTransport(
      use_json=True, # required for GitHub API
      url='https://api.github.com/graphql',
      headers={
        'Authorization': 'token {}'.format(token)
      }
    )
  )

  query = gql.gql('''
    query {
      repository(owner: "''' + repoowner + '''", name: "''' + reponame + '''") {
        pullRequests(first: 10,
                     states: OPEN,
                     orderBy: {field: UPDATED_AT, direction: DESC}) {
          edges {
            node {
              title
              id
              updatedAt
              state
              comments(first: 6) {
                edges {
                  node {
                    id
                    createdAt
                    author {
                      login
                    }
                  }
                }
              }
            }
          }
        }
      }
      rateLimit {
        limit
        cost
        remaining
        resetAt
      }
    }
  ''')
  return client.execute(query)

