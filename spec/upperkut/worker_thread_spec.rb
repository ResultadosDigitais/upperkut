require 'spec_helper'
require 'upperkut/manager'

module Upperkut
  RSpec.describe WorkerThread do
    subject(:worker_thread) { described_class.new(manager, processor) }

    let(:manager) { DummyManager.new }
    let(:processor) { DummyProcessor.new }

    class DummyManager
      attr_reader :logger

      def initialize
        @logger = Logger.new(nil)
      end

      def notify_killed_processor(_worker_thread); end
    end

    class DummyProcessor
      attr_reader :processing

      def initialize
        @processing = false
      end

      def process_blocking
        @processing = true
      end

      def stop
        @processing = false
      end
    end

    before do
      allow(Thread).to receive(:new).and_yield
    end

    describe '#run' do
      it 'spawns a thread' do
        worker_thread.run
        expect(Thread).to have_received(:new)
      end

      it 'starts the processor' do
        worker_thread.run
        expect(processor.processing).to be_truthy
      end
    end

    describe '#stop' do
      before { worker_thread.run }

      it 'stops the processor' do
        worker_thread.stop
        expect(processor.processing).to be_falsey
      end
    end
  end
end
