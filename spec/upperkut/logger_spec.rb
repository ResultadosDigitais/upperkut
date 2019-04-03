require 'spec_helper'
require 'upperkut/logging'

module Upperkut
  RSpec.describe Logging do
    let(:logger) { Logging.initialize_logger }

    context 'with hash messages' do
      it 'key-value format and puts them' do
        expect do
          logger.info(op: 'action', msg: 'performing op')
        end.to output(/upperkut:\s.*hostname\=.*\spid=\d{1,}\sseverity=INFO\sop=action\smsg=performing op/).to_stdout
      end
    end

    context 'with regular messages' do
      it 'key-value format with msg key' do
        expect do
          logger.info('shutting down')
        end.to output(/upperkut:\s.*hostname\=.*\spid=\d{1,}\sseverity=INFO\smsg=shutting down/).to_stdout
      end
    end
  end
end
