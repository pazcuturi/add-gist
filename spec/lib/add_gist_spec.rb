require 'spec_helper'
require 'add_gist'
require 'byebug'

describe AddGist do
  describe '.upload_files' do
    subject do
      AddGist.upload_files(path, options)
    end
    let(:options) {}

    context 'when given nonexistent path' do
      let(:path) { 'xyz' }
      it { expect { subject }.to output(%(The path '#{path}' does not exist.\n)).to_stdout }
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

    let(:progress_bar) { Net::HTTP::UploadProgress }
    let(:http_post) { Net::HTTP::Post }

    context 'when given nonempty directory path' do
      let(:path) { 'nonempty' }
      let(:options) { { is_public: false, description: 'Awesome gist' } }
      it 'returns status 201' do
        FakeFS do
          Dir.mkdir(path)
          File.open("#{path}/text.txt", 'w') { |f| f.write('Text content') }

          expect_any_instance_of(progress_bar).to receive(:initialize).with(instance_of(http_post))

          stub_request(:post, "https://api.github.com/gists?access_token=#{ENV['ACCESS_TOKEN']}")
            .with(
              body: "{\"description\":\"Awesome gist\",\"public\":false,\"files\":{\"text.txt\":{\"content\":\"Text content\"}}}",
              headers: {
                'Accept' => '*/*',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Length' => '93',
                'User-Agent' => 'Ruby'
              }
            )
            .to_return(status: 201, body: %({"html_url": "https://gist.github.com/someUrl"}))
          subject
        end
      end
    end

    context 'when given existing file path' do
      let(:path) { 'file.txt' }
      let(:options) { {is_public: true, description: 'Gist with new file'} }
      it 'returns status 201' do
        FakeFS do
          File.open("#{path}", 'w') { |f| f.write('New file') }

          expect_any_instance_of(progress_bar).to receive(:initialize).with(instance_of(http_post))

          stub_request(:post, "https://api.github.com/gists?access_token=#{ENV['ACCESS_TOKEN']}")
            .with(
              body: "{\"description\":\"Gist with new file\",\"public\":true,\"files\":{\"file.txt\":{\"content\":\"New file\"}}}",
              headers: {
                'Accept' => '*/*',
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Length' => '94',
                'User-Agent' => 'Ruby'
              }
            )
            .to_return(status: 201, body: %({"html_url": "https://gist.github.com/someUrl"}))
          subject
        end
      end
    end
  end
end
