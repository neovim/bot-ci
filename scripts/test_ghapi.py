import pytest
import sys
import os
sys.path.insert(0,
    os.path.join(os.path.dirname(os.path.abspath(__file__)), '../src'))
import ghapi

def test_get_comments_by_author():
  result = ghapi.get_recent_pr_comments(
      'neovim',
      'neovim',
      )
  # import pprint
  # pp = pprint.PrettyPrinter(indent=2)
  # pp.pprint(result)
  assert result['rateLimit']['limit'] == 5000
  assert result['rateLimit']['cost'] == 1
  assert not (result['repository']['pullRequests']['edges'] is None)
  assert result == {}
