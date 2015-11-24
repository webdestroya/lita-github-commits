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

* `repos` (Hash) - A map of repositories to allow notifications for and the chat rooms to post them in. The keys should be strings in the format "github_username/repository_name" and the values should be either a string room name or an array of string room names. If you do not wish to have notifications for a particular repository, set it's room array to "".  Default: `{}`.

* remember_commits_for (Integer) - Number of days lita will remember information about commits it as heard about.  Setting it to 0 effectively disables the "commit/SHA" command handling.  Default: 0 (no memory)

* github_webhook_secret (String) - Optional secret that github uses to sign the webhook requests with.  Currently the configuration's presence only requires that the requests from GitHub be signed.  Default: nil (no signature required)

### Example Config

``` ruby
Lita.configure do |config|
  config.handlers.github_commits.repos = {
    "username/repo1" => "#someroom",
    "username/repo2" => ["#someroom", "#someotherroom"],
    "username/muted_repo3" => ""
  }
  config.handlers.github_commits.remember_commits_for = 7
  config.handlers.github_commits.github_webhook_secret = "secr3tC0de"
end
```

**Note**: For HipChat, the room should be the JID of the HipChat room (eg. `123_development@conf.hipchat.com`)

The output from Lita would look something like:

```
[GitHub] Got 3 new commits from Garen Torikian on octokitty/testing on the master branch
  * 32e3221: Test
  * adc2112: This is me testing the windows client.
  * 441ab6c: Rename madame-bovary.txt to words/madame-bovary.txt
```

## Usage

You will need to add a [GitHub Webhook](https://developer.github.com/webhooks/) url that points to: `http://address.of.lita:8080/github-commits`

In any room that Lita is listening, it will look for statements of the following form and provide the details of the commit if it remembers them.  If it doesn't remember the commit (or has heard about it), it will remain silent unless its a direct command.
```
... commit/<SHA1>...       - Search for a commit and return the details if found

```

Note that it only searches the commits that it has heard about and remembers so that the bot needs no more access to the repo than a webhook.

## License

[MIT](http://opensource.org/licenses/MIT)
