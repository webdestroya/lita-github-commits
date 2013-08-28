# lita-github-commits

[![Build Status](https://travis-ci.org/webdestroya/lita-github-commits.png)](https://travis-ci.org/webdestroya/lita-github-commits)
[![Code Climate](https://codeclimate.com/github/webdestroya/lita-github-commits.png)](https://codeclimate.com/github/webdestroya/lita-github-commits)
[![Coverage Status](https://coveralls.io/repos/webdestroya/lita-github-commits/badge.png)](https://coveralls.io/r/webdestroya/lita-github-commits)

**lita-github-commits** is a handler for [Lita](https://github.com/jimmycuadra/lita) that listens for github commits and posts them in the channel.

## Installation

Add lita-github-commits to your Lita instance's Gemfile:

``` ruby
gem "lita-github-commits"
```

## Configuration

### Required attributes

* `repos` (Hash) - A map of repositories to allow notifications for and the chat rooms to post them in. The keys should be strings in the format "github_username/repository_name" and the values should be either a string room name or an array of string room names. Default: `{}`.

### Example

``` ruby
Lita.configure do |config|
  config.handlers.github_commits.repos = {
    "username/repo1" => "#someroom",
    "username/repo2" => ["#someroom", "#someotherroom"]
  }
end
```

## Usage

You will need to add a GitHub Webhook url that points to: `http://address.of.lita/github-commits`

## License

[MIT](http://opensource.org/licenses/MIT)
