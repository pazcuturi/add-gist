require 'add_gist'

describe AddGist do

  describe '.read_files' do
    context 'given no path' do
      it 'returns files on current directory' do
        expect(AddGist.read_files('add_gist.rb')). to have_key('add_gist.rb')
      end
    end

    context 'given unexisting path' do
      it 'returns error' do
        expect(AddGist.read_files('xyz')).to raise_error(Errno::ENOENT, 'The path xyz does not exist.')
      end
    end

    context 'given empty directory path' do
      it 'returns no files' do
        expect(AddGist.read_files('empty')).to be_empty
      end
    end

    context 'given existing directory path' do
      it 'returns all files' do
        hash = AddGist.read_files('prueba')
        expect(hash).to have_key('prueba.txt')
        expect(hash).to have_key('prueba2.txt')
      end
    end

    context 'given existing file path' do
      it 'returns that file' do
        expect(AddGist.read_files('add_gist.rb')). to have_key('add_gist.rb')
      end
    end
  end
end
