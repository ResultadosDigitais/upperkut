require 'spec_helper'
require 'upperkut/middlewares/datadog'

RSpec.describe Upperkut::Middlewares::Datadog do
  before do
    stub_const 'Datadog', Class.new
    Datadog.class_eval do
      def self.tracer
        @tracer ||= Tracer
      end
    end

    stub_const 'Tracer', Class.new
    Tracer.class_eval do
      def self.trace(args)
        yield
      end
    end

    stub_const 'UpperkutWorker', Class.new
  end

  describe 'call' do
    it 'trace execution with Datadog' do
      expect(Tracer).to receive(:trace).with('UpperkutWorker')
      described_class.new.call(UpperkutWorker, [])
    end

    context 'when block is given' do
      it 'yields' do
        expect do |block|
          described_class.new.call(UpperkutWorker, [], &block)
        end.to yield_with_no_args
      end
    end
  end
end
