require 'spec_helper'
require 'upperkut/job'

module Upperkut
  RSpec.describe Job do
    subject(:job) { described_class.new({ my_property: 1 }, current_timestamp) }

    let(:current_timestamp) { Time.now.utc.to_i }

    it 'allows accessing body properties like a hash' do
      job[:my_another_property] = 2

      expect(job[:my_another_property]).to eq(2)
    end

    describe '#initialize' do
      context 'when the enqueued at is not informed' do
        let(:current_timestamp) { nil }

        it 'uses the current timestamp as fallback' do
          expect(job.enqueued_at).to be_within(1).of(Time.now.to_i)
        end
      end
    end

    describe '#to_json' do
      subject { job.to_json }

      it do
        expected_hash = {
          body: { my_property: 1 },
          enqueued_at: current_timestamp,
        }

        is_expected.to eq(expected_hash.to_json)
      end
    end

    describe '.from_json' do
      subject(:unserialized_job) { described_class.from_json(job_json) }

      let(:job_json) do
        {
          body: { my_property: 1 },
          enqueued_at: current_timestamp,
        }.to_json
      end

      it 'fetches the job body from the json' do
        expect(unserialized_job.body).to eq({ 'my_property' => 1 })
      end

      it 'fetches the job enqueued_at from the json' do
        expect(unserialized_job.enqueued_at).to eq(current_timestamp)
      end
    end
  end
end

