require 'spec_helper'
require 'add_gist'

describe AddGist do
  describe '.read_files' do
    context 'when given unexisting path' do
      it 'returns error message' do
        expect { AddGist.send :read_files, 'xyz' }.to output(%(The path 'xyz' does not exist.\n)).to_stdout
      end
    end

    context 'when given empty directory path' do
      it 'returns no files' do
        expect(AddGist.send(:read_files, 'empty')).to be_empty
      end
    end

    context 'when given existing directory path' do
      let(:files) { AddGist.send(:read_files, 'prueba') }
      it 'returns all files' do
        expect(files).to have_key('prueba.txt')
        expect(files).to have_key('prueba2.txt')
      end
    end

    context 'when given existing file path' do
      it 'returns that file' do
        expect(AddGist.send(:read_files, 'lib/add_gist.rb')). to have_key('add_gist.rb')
      end
    end
  end

  describe '.calculate_progress' do
    context 'with total == amount' do
      it 'returns 100%' do
        expect(AddGist.send(:calculate_progress, 200, 200)).to eq(100.0)
      end
    end

    context 'with total == 0' do
      it 'returns infinity' do
        expect(AddGist.send(:calculate_progress, 0, 100)).to eq(Float::INFINITY)
      end
    end

    context 'with two positive numbers' do
      it 'returns the percentage' do
        expect(AddGist.send(:calculate_progress, 100, 25)).to eq(25.0)
      end
    end
  end

  describe '.build_request' do
    let(:var) { AddGist.send(:build_request) }
    it 'returns http and request' do
      expect(var[0]).to be_instance_of(Net::HTTP)
      expect(var[0].use_ssl?).to be true
      expect(var[1]).to be_instance_of(Net::HTTP::Post)
    end
  end
end
