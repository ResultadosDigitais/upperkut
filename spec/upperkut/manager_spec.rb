require 'spec_helper'
require 'upperkut/manager'

module Upperkut
  RSpec.describe Manager do
    subject(:manager) { described_class.new(worker: DummyWorker.to_s, concurrency: 5) }

    let(:worker_thread_stub) do
      instance_double(WorkerThread, run: nil, stop: nil, kill: nil)
    end

    class DummyWorker
      include Upperkut::Worker

      def perform(_events); end
    end

    before do
      allow(WorkerThread).to receive(:new).and_return(worker_thread_stub)
    end

    describe '#initialize' do
      it 'initialize and instance correct attributes' do
        manager = described_class.new(
          worker: DummyWorker.to_s,
          concurrency: 24
        )

        expect(manager.stopped).to be_falsey
        expect(manager.concurrency).to eq 24
        expect(manager.worker).to eq Upperkut::DummyWorker
        expect(manager.logger).to be_instance_of Logger
      end
    end

    describe '#run' do
      it 'spawns a given number of threads' do
        manager.run
        expect(worker_thread_stub).to have_received(:run).exactly(5).times
      end
    end

    describe '#stop' do
      before { manager.run }

      it 'stops all threads' do
        manager.stop
        expect(worker_thread_stub).to have_received(:stop).exactly(5).times
      end
    end

    describe '#kill' do
      before { manager.run }

      it 'kills all threads' do
        manager.kill
        expect(worker_thread_stub).to have_received(:kill).exactly(5).times
      end
    end
  end
end
