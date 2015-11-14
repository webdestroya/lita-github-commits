# lita-github-commits

[![Build Status](https://travis-ci.org/webdestroya/lita-github-commits.png)](https://travis-ci.org/webdestroya/lita-github-commits)
[![Code Climate](https://codeclimate.com/github/webdestroya/lita-github-commits.png)](https://codeclimate.com/github/webdestroya/lita-github-commits)
[![Coverage Status](https://coveralls.io/repos/webdestroya/lita-github-commits/badge.png)](https://coveralls.io/r/webdestroya/lita-github-commits)

**lita-github-commits** is a handler for [Lita](https://github.com/jimmycuadra/lita) that listens for github commits and posts them in the channel.  You can also ask lita for information about a commit it remembers.

## Installation

Add lita-github-commits to your Lita instance's Gemfile:

``` ruby
gem "lita-github-commits"
```

## Configuration

### Required attributes

* `repos` (Hash) - A map of repositories to allow notifications for and the chat rooms to post them in. The keys should be strings in the format "github_username/repository_name" and the values should be either a string room name or an array of string room names. Default: `{}`.

* remember_commits_for (Integer) - Number of days lita will remember information about commits it as heard about.  Default: 0 (no memory)

### Example

``` ruby
Lita.configure do |config|
  config.handlers.github_commits.repos = {
    "username/repo1" => "#someroom",
    "username/repo2" => ["#someroom", "#someotherroom"]
  }
end
```

**Note**: For HipChat, the room should be the JID of the HipChat room (eg. `123_development@conf.hipchat.com`)

The output from Lita would look something like:

```
[GitHub] Got 3 new commits from Garen Torikian on octokitty/testing on the master branch
  * Test
  * This is me testing the windows client.
  * Rename madame-bovary.txt to words/madame-bovary.txt
```

## Usage

You will need to add a GitHub Webhook url that points to: `http://address.of.lita/github-commits`

```
... commit/<SHA1>...       - Search for a commit based and return the details

```

Note that it only looks through the commits that it has heard about and remembers.  This is so that the bot needs no more access than a webhook.

## License

[MIT](http://opensource.org/licenses/MIT)
