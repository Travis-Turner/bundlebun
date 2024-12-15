# frozen_string_literal: true

RSpec.describe Bundlebun::Runner do
  let(:runner) { described_class.new }

  before do
    allow_any_instance_of(described_class).to receive(:exec) do |_instance, _command|
      true
    end
  end

  describe 'with vendor directory' do
    describe 'relative' do
      it 'returns the vendor/bun path' do
        expect(described_class.relative_directory).to eq('lib/bundlebun/vendor/bun')
      end
    end

    describe 'with full directory path' do
      let(:expected_path) { File.expand_path('../../../lib/bundlebun/vendor/bun', __dir__) }

      it 'returns absolute path to vendor/bun directory' do
        expect(described_class.full_directory).to eq(expected_path)
      end
    end
  end

  describe 'returning path to the binary' do
    context 'on Unix-like systems' do
      before do
        allow(described_class).to receive(:binary_path).and_call_original
        stub_const('RUBY_PLATFORM', 'x86_64-linux')
      end

      it 'returns path with bun binary' do
        expect(File.basename(described_class.binary_path)).to eq('bun')
      end
    end

    context 'on Windows' do
      before do
        allow(described_class).to receive(:binary_path).and_call_original
        stub_const('RUBY_PLATFORM', 'mswin')
      end

      it 'returns path with bun.exe binary' do
        expect(File.basename(described_class.binary_path)).to eq('bun.exe')
      end
    end
  end

  describe 'when checking binary existence' do
    it 'returns true when binary exists' do
      allow(File).to receive(:exist?).with(described_class.binary_path).and_return(true)
      expect(described_class.binary_path_exist?).to be true
    end

    it 'returns false when binary does not exist' do
      allow(File).to receive(:exist?).with(described_class.binary_path).and_return(false)
      expect(described_class.binary_path_exist?).to be false
    end
  end

  describe 'binstub handling' do
    it 'returns the binstub path' do
      expect(described_class.binstub_path).to eq('bin/bun')
    end

    context 'when binstub exists' do
      before do
        allow(File).to receive(:exist?).with('bin/bun').and_return(true)
      end

      it 'returns true' do
        expect(described_class.binstub_exist?).to be true
      end
    end

    context 'when binstub does not exist' do
      before do
        allow(File).to receive(:exist?).with('bin/bun').and_return(false)
      end

      it 'returns false' do
        expect(described_class.binstub_exist?).to be false
      end
    end

    describe 'returning binstub or true binary path' do
      let(:binary_path) { described_class.binary_path }

      context 'when binstub exists' do
        before do
          allow(File).to receive(:exist?).with('bin/bun').and_return(true)
        end

        it 'returns binstub path' do
          expect(described_class.binstub_or_binary_path).to eq('bin/bun')
        end
      end

      context 'when binstub does not exist' do
        before do
          allow(File).to receive(:exist?).with('bin/bun').and_return(false)
        end

        it 'returns binary path' do
          expect(described_class.binstub_or_binary_path).to eq(binary_path)
        end
      end
    end
  end

  context 'running Bun' do
    let(:binary_path) { described_class.binary_path }

    before do
      allow(File).to receive(:exist?).with(binary_path).and_return(true)
    end

    it 'executes bun with given string arguments' do
      runner = described_class.new('install --no-save')
      expect(runner).to receive(:exec).with("#{binary_path} install --no-save")
      runner.call
    end

    it 'executes bun with given array arguments' do
      runner = described_class.new(['install', '--no-save'])
      expect(runner).to receive(:exec).with("#{binary_path} install --no-save")
      runner.call
    end

    it 'executes bun without arguments' do
      runner = described_class.new
      expect(runner).to receive(:exec).with(binary_path)
      runner.call
    end

    it 'exits with code 127 if bun executable does not exist' do
      allow(File).to receive(:exist?).with(described_class.binary_path).and_return(false)
      expect(Kernel).to receive(:warn)
      expect(Kernel).to receive(:exit).with(127)

      described_class.call('test')
    end
  end
end