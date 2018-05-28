require 'spec_helper'
require 'add_gist'

describe AddGist do
  describe '.upload_files' do
    subject { AddGist.upload_files(path, options) }
    let(:options) {}
    let(:progress_bar) { Net::HTTP::UploadProgress }
    let(:http_post) { Net::HTTP::Post }
    let(:url) { "https://api.github.com/gists?access_token=#{ENV['ACCESS_TOKEN']}" }

    context 'when given nonexistent path' do
      let(:path) { 'xyz' }
      let(:output_msg) { %(The path '#{path}' does not exist.\n) }
      it { expect { subject }.to output(output_msg).to_stdout }
    end

    context 'when given empty directory path' do
      let(:path) { 'empty' }
      it 'returns nil' do
        FakeFS do
          Dir.mkdir(path)
          expect(subject).to be_nil
        end
      end
    end

    context 'when given nonempty directory path' do
      let(:path) { 'nonempty' }
      let(:options) { { is_public: false, description: 'Awesome gist' } }
      let(:req_body) do
        { body: "{\"description\":\"Awesome gist\",\"public\":false,\"files\":{\"text.txt\":{\"content\":\"Text content\"}}}",
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Content-Length' => '93',
            'User-Agent' => 'Ruby'
          } }
      end
      let(:req_response) { { status: 201, body: %({"html_url": "https://gist.github.com/1234"}) } }
      let(:output_msg) { %(Gist created successfully! \nAccess URL: https://gist.github.com/1234\n) }
      it "prints the gist's url" do
        FakeFS do
          Dir.mkdir(path)
          File.open("#{path}/text.txt", 'w') { |f| f.write('Text content') }

          expect_any_instance_of(progress_bar).to receive(:initialize).with(instance_of(http_post))

          stub_request(:post, url).with(req_body).to_return(req_response)
          expect { subject }.to output(output_msg).to_stdout
        end
      end
    end

    let(:path) { 'file.txt' }
    let(:options) { { is_public: true, description: 'Gist with new file' } }
    let(:req_body) do
      { body: "{\"description\":\"Gist with new file\",\"public\":true,\"files\":{\"file.txt\":{\"content\":\"New file\"}}}",
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Length' => '94',
          'User-Agent' => 'Ruby'
        } }
    end
    let(:req_response) { { status: 201, body: %({"html_url": "https://gist.github.com/8989"}) } }
    let(:output_msg) { %(Gist created successfully! \nAccess URL: https://gist.github.com/8989\n) }

    context 'when given existing file path' do
      it "prints the gist's url" do
        FakeFS do
          File.open(path.to_s, 'w') { |f| f.write('New file') }

          expect_any_instance_of(progress_bar).to receive(:initialize).with(instance_of(http_post))

          stub_request(:post, url).with(req_body).to_return(req_response)
          expect { subject }.to output(output_msg).to_stdout
        end
      end
    end

    context 'when error occurs' do
      after do
        $stdin = STDIN
      end

      context 'when no retry' do
        let(:output_msg) { %(The following error occurred: 'Exception from WebMock'. \nWould you like to resume (y/n)?\n) }

        before do
          $stdin = StringIO.new("no\n")
        end

        it 'it exits' do
          FakeFS do
            File.open(path.to_s, 'w') { |f| f.write('New file') }
            expect_any_instance_of(progress_bar).to receive(:initialize).with(instance_of(http_post))
            stub_request(:post, url).to_raise(StandardError)
            expect do
              expect { subject }.to raise_error(SystemExit)
            end.to output(output_msg).to_stdout
          end
        end
      end

      context 'when retry' do
        let(:output_msg) do
          "The following error occurred: 'Exception from WebMock'. \nWould you like to resume (y/n)?\n"\
          "The following error occurred: 'Exception from WebMock'. \nWould you like to resume (y/n)?\n"
        end

        before do
          $stdin = StringIO.new("yes\n")
        end

        it "desn't exit if retry == yes" do
          FakeFS do
            File.open(path.to_s, 'w') { |f| f.write('New file') }
            expect_any_instance_of(progress_bar).to receive(:initialize).with(instance_of(http_post))
            stub_request(:post, url).to_raise(StandardError)
            expect do
              expect { subject }.not_to raise_error(SystemExit)
            end.to output(output_msg).to_stdout
          end
        end
      end
    end
  end
end
