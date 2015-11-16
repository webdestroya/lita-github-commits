require "lita"
require 'time'

module Lita
  module Handlers
    class GithubCommits < Handler
      template_root File.expand_path("../../../../templates", __FILE__)


      #todo: change this to lita4 config http://docs.lita.io/releases/4/
      #config :repos, type: Hash, default: {}
      #config :remember_commits_for, type: Integer, default: 1
      def self.default_config(config)
        config.repos = {}
        config.remember_commits_for = 1
      end

      def self.install_routes()
        http.post "/github-commits", :receive
      end
      install_routes()

      SHA_ABBREV_LENGTH = 7  #note the regex below needs to match this constant
      def self.install_commands
        route(/commit\/([a-f0-9]{7,})\s?/i, :check_for_commit, command: false,
              help: { "...commit/<SHA1>..." => "Displays the details of commit SHA1 if known (requires at least #{SHA_ABBREV_LENGTH} digits of the SHA)."}
        )
      end
      install_commands

      def check_for_commit(response)
        sha = abbrev_sha(response.match_data[1])
        if sha.nil? || sha.empty?
          #this shouldn't match regex
          response.reply("[GitHub] I need at least #{SHA_ABBREV_LENGTH} characters of the commit SHA") if response.message.command?
        elsif sha.size <= 6 && response.message.command?
          #this shouldn't match regex
          response.reply("[GitHub] Can you be more precise?")
        elsif  (commit=redis.get(sha))
          response.reply(render_template("commit_details", commit: parse_payload(commit)))
        elsif response.message.command?
          response.reply("[GitHub] Sorry Boss, I can't find that commit")
        #else
        #  response.reply("I got nothing to say about #{sha}.")
        end
      end

      def receive(request, response)
        event_type = request.env['HTTP_X_GITHUB_EVENT'] || 'unknown'
        if event_type == "push"
          payload = parse_payload(request.params['payload']) or return
          store_commits(payload)
          repo = get_repo(payload)
          notify_rooms(repo, payload)
        elsif event_type == "ping"
          response.status = 200
          response.write "Working!"
        else
          response.status = 404
        end
      end

      private

      def parse_payload(payload)
        MultiJson.load(payload)
      rescue MultiJson::LoadError => e
        Lita.logger.error("Could not parse JSON payload from Github: #{e.message}")
        return
      end

      def notify_rooms(repo, payload)
        rooms = rooms_for_repo(repo) or return
        message = format_message(payload)

        rooms.each do |room|
          target = Source.new(room: room)
          robot.send_message(target, message)
        end
      end

      def store_commits(payload)
        ttl = remember_commits_for*86400
        return if ttl == 0
        commits = payload['commits']
        branch = branch_from_ref(payload['ref'])
        commits.each do |commit|
          key = commit['id'][0,SHA_ABBREV_LENGTH]
          commit[:branch] = branch
          #puts("storing #{commit.to_json} to key #{key} for #{ttl}")
          redis.setex(key,ttl,commit.to_json)
        end
      end

      def format_message(payload)
        commits = payload['commits']
        branch = branch_from_ref(payload['ref'])
        if commits.size > 0
          author = committer_and_author(commits.first)
          messages = commit_messages(commits)
          commit_pluralization = commits.size > 1 ? 'commits' : 'commit'
          "[GitHub] Got #{commits.size} new #{commit_pluralization} #{author} on #{payload['repository']['owner']['name']}/#{payload['repository']['name']} on the #{branch} branch\n" + messages.join("\n")
        elsif payload['created']
          "[GitHub] #{payload['pusher']['name']} created: #{payload['ref']}: #{payload['base_ref']}"
        elsif payload['deleted']
          "[GitHub] #{payload['pusher']['name']} deleted: #{payload['ref']}"
        end
      rescue
        Lita.logger.warn "Error formatting message for payload: #{payload}"
        return
      end

      def abbrev_sha(sha)
        sha.nil? ? nil : sha[0,SHA_ABBREV_LENGTH]
      end

      def branch_from_ref(ref)
        ref.split('/').last
      end

      def committer_and_author(commit)
        if commit['author']['username'] != commit['committer']['username']
          "authored by #{commit['author']['name']} and committed by " +
            "#{commit['committer']['name']}"
        else
          "from #{commit['author']['name']}"
        end
      end

      def commit_messages(commits)
        commits.collect do |commit|
          "  * #{commit['message']}"
        end
      end

      def rooms_for_repo(repo)
        rooms = Lita.config.handlers.github_commits.repos[repo]

        if rooms && rooms.size > 0 
          Array(rooms)
        else
          Lita.logger.warn "Notification from GitHub Commits for unconfigured project: #{repo}"
          return
        end
      end

      def get_repo(payload)
        "#{payload['repository']['owner']['name']}/#{payload['repository']['name']}"
      end
      
      def remember_commits_for
        Lita.config.handlers.github_commits.remember_commits_for
      end
    end

    Lita.register_handler(GithubCommits)
  end
end
