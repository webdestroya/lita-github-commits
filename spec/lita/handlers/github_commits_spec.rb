require "spec_helper"
require_relative "payload"

describe Lita::Handlers::GithubCommits, lita_handler: true do

  include Payload

  it { routes_http(:post, "/github-commits").to(:receive) }

  describe "#receive" do

    let(:request) do
      request = double("Rack::Request")
      allow(request).to receive(:env).and_return({"HTTP_X_GITHUB_EVENT" => "push"})
      allow(request).to receive(:params).and_return(params)
      request
    end

    let(:response) { Rack::Response.new }

    let(:params) { double("Hash") }

    context "request with commits" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        allow(params).to receive(:[]).with("payload").and_return(valid_payload)
      end

      it "sends a notification message to the applicable rooms" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(target.room).to eq("#baz")
          expect(message).to eq(<<-RESPONSE.chomp
[GitHub] Got 3 new commits from Garen Torikian on octokitty/testing on the master branch
  * Test
  * This is me testing the windows client.
  * Rename madame-bovary.txt to words/madame-bovary.txt
                                RESPONSE
                               )
        end
        expect(subject.redis).to receive(:setex).exactly(3).times
        subject.receive(request, response)
      end
    end

    context "request with one commit" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        Lita.config.handlers.github_commits.remember_commits_for = 1
        allow(params).to receive(:[]).with("payload").and_return(
          valid_payload_one_commit)
      end

      it "sends a singular commit notification message to the applicable rooms" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(target.room).to eq("#baz")
          expect(message).to eq(<<-RESPONSE.chomp
[GitHub] Got 1 new commit from Garen Torikian on octokitty/testing on the master branch
  * Test
                                RESPONSE
                               )
        end
        expect(subject.redis).to receive(:setex).once
        subject.receive(request, response)
      end

      it "stores the message to redis with ttl" do
        expect(subject.redis).to receive(:setex).once.with("c441029",86400,anything)
        subject.receive(request, response)
      end

      it { is_expected.to route_command("zzcommit/1234567").to(:check_for_commit) }
      it { is_expected.to route_command("abf commit/1234567").to(:check_for_commit) }
      it { is_expected.to route_command("__commit/abcdef1?").to(:check_for_commit) }
      it { is_expected.to_not route_command("commit/").to(:check_for_commit) }
      it { is_expected.to_not route_command("commit/123456").to(:check_for_commit) }
      it { is_expected.to_not route_command("commit/ornottocommit").to(:check_for_commit) }


      it "stores the message to redis and can retrieve it from redis" do
        subject.receive(request, response)
        expect(subject.redis.ttl("c441029")).to be 
        expect(subject.redis.get("c441029")).to eq first_commit.merge({:branch=>"master"}).to_json
        expect(subject.redis.get("c44102")).to be nil
      end
    end

    context "request without memory" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        Lita.config.handlers.github_commits.remember_commits_for = 0
        allow(params).to receive(:[]).with("payload").and_return(
          valid_payload_one_commit)
      end

      it "stores does not store the message to redis" do
        expect(subject.redis).to receive(:setex).never
        subject.receive(request, response)
      end
    end

    context "request with commits" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        allow(params).to receive(:[]).with("payload").and_return(valid_payload_diff_committer)
      end

      it "sends a notification message to the applicable rooms" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(message).to eq(<<-RESPONSE.chomp
[GitHub] Got 3 new commits authored by Garen Torikian and committed by Repository Owner on octokitty/testing on the master branch
  * Test
  * This is me testing the windows client.
  * Rename madame-bovary.txt to words/madame-bovary.txt
                                RESPONSE
                               )
        end
        subject.receive(request, response)
      end
    end

    context "request with commits on a repo with no room" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = ""
        allow(params).to receive(:[]).with("payload").and_return(valid_payload_diff_committer)
      end

      it "it should not send messages on webhook requests" do
        expect(robot).not_to receive(:send_message) 
        subject.receive(request, response)
      end

      it "it should respond to a previously unseen commit if its a command" do
        send_command("stuff commit/36c5f2243ed24de5 stuff")
        expect(replies).to include("[GitHub] Sorry Boss, I can't find that commit")
      end

      it "it should not respond to a previously unseen commit if its not a command" do
        send_message("github commit/36c5f2243ed24de5")
        expect(replies).to eq []
      end

      it "it should respond to a previously seen commit" do
        subject.receive(request, response)
        send_message("do you know about commit/36c5f2243ed24de5?")
        expect(replies).to include("[GitHub] Commit 36c5f22 committed by Repository Owner on branch master at 2013-02-22 17:07:13 -0500 with message\n'This is me testing the windows client.'\nand changes to files\nREADME.md")
      end
    end


    context "create payload" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        allow(params).to receive(:[]).with("payload").and_return(created_payload)
      end

      it "sends a notification message to the applicable rooms" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(target.room).to eq("#baz")
          expect(message).to include("[GitHub] Garen Torikian created")
        end
        subject.receive(request, response)
      end
    end


    context "delete payload" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        allow(params).to receive(:[]).with("payload").and_return(deleted_payload)
      end

      it "sends a notification message to the applicable rooms" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(target.room).to eq("#baz")
          expect(message).to include("[GitHub] Garen Torikian deleted")
        end
        subject.receive(request, response)
      end
    end


    context "bad payload" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        allow(params).to receive(:[]).with("payload").and_return("yaryary")
      end

      it "sends a notification message to the applicable rooms" do
        expect(Lita.logger).to receive(:error) do |error|
          expect(error).to include("Could not parse JSON payload from Github")
        end
        subject.receive(request, response)
      end
    end


    context "ping event" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        allow(params).to receive(:[]).with("payload").and_return(ping_payload)
        allow(request).to receive(:env).and_return({"HTTP_X_GITHUB_EVENT" => "ping"})
      end

      it "handles the ping event" do
        expect(Lita.logger).to_not receive(:error)
        expect(response).to receive(:write).with("Working!")
        subject.receive(request, response)
      end
    end

    context "unknown event" do
      before do
        Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
        allow(params).to receive(:[]).with("payload").and_return(ping_payload)
        allow(request).to receive(:env).and_return({"HTTP_X_GITHUB_EVENT" => "fakefake"})
      end

      it "handles the ping event" do
        expect(Lita.logger).to_not receive(:error)
        expect(response).to_not receive(:write)
        subject.receive(request, response)
      end
    end


    context "improper config" do
      before do
        allow(params).to receive(:[]).with("payload").and_return(deleted_payload)
      end

      it "sends a notification message to the applicable rooms" do
        expect(Lita.logger).to receive(:warn) do |warning|
          expect(warning).to include("Notification from GitHub Commits for unconfigured project")
        end
        subject.receive(request, response)
      end
    end

  end

end
