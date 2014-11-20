require "spec_helper"
require_relative "payload"

describe Lita::Handlers::GithubCommits, lita_handler: true do
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

    let(:valid_payload) do
        Payload.valid_payload
    end

    let(:created_payload) do
      Payload.created_payload
    end

    let(:deleted_payload) do
      Payload.deleted_payload
    end

    let(:ping_payload) do
      Payload.ping_payload
    end


      context "request with commits" do
        before do
          Lita.config.handlers.github_commits.repos["octokitty/testing"] = "#baz"
          allow(params).to receive(:[]).with("payload").and_return(valid_payload)
        end

        it "sends a notification message to the applicable rooms" do
          expect(robot).to receive(:send_message) do |target, message|
            expect(target.room).to eq("#baz")
            expect(message).to eq(
              "[GitHub] Got 3 new commits from Garen Torikian on octokitty/testing")
          end
          subject.receive(request, response)
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
