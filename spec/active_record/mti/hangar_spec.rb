require 'spec_helper'

describe 'Hangar message hierarchy' do
  let!(:session) { Session.create(name: 'test-session') }

  describe 'table name inference' do
    it 'infers child table names from parent' do
      expect(Messages::UserMessage.table_name).to eq('message/user_messages')
      expect(Messages::AssistantResponse.table_name).to eq('message/assistant_responses')
      expect(Messages::ToolInvocation.table_name).to eq('message/tool_invocations')
      expect(Messages::ToolResult.table_name).to eq('message/tool_results')
      expect(Messages::SystemEvent.table_name).to eq('message/system_events')
    end

    it 'identifies MTI tables' do
      expect(Message).to be_mti
      expect(Messages::UserMessage).to be_mti
      expect(Messages::AssistantResponse).to be_mti
      expect(Messages::ToolInvocation).to be_mti
      expect(Messages::ToolResult).to be_mti
      expect(Messages::SystemEvent).to be_mti
    end
  end

  describe 'CRUD operations' do
    it 'creates records in child tables' do
      msg = Messages::UserMessage.create!(session: session, sequence: 1, content: 'Hello', role: 'user')
      expect(msg).to be_persisted
      expect(msg.role).to eq('user')
    end

    it 'creates different message types' do
      Messages::UserMessage.create!(session: session, sequence: 1, content: 'Hello', role: 'user')
      Messages::AssistantResponse.create!(session: session, sequence: 2, content: 'Hi there', model: 'claude-3', token_count: 42)
      Messages::ToolInvocation.create!(session: session, sequence: 3, content: '{}', tool_name: 'read_file', arguments: { path: '/tmp/test' })
      Messages::ToolResult.create!(session: session, sequence: 4, content: 'file contents', tool_name: 'read_file', success: true, output: 'ok')
      Messages::SystemEvent.create!(session: session, sequence: 5, content: 'compacted', event_type: 'compaction')

      expect(Message.count).to eq(5)
    end
  end

  describe 'querying' do
    before do
      Messages::UserMessage.create!(session: session, sequence: 1, content: 'Hello', role: 'user')
      Messages::AssistantResponse.create!(session: session, sequence: 2, content: 'Hi', model: 'claude-3', token_count: 10)
      Messages::ToolInvocation.create!(session: session, sequence: 3, content: '{}', tool_name: 'bash')
      Messages::ToolResult.create!(session: session, sequence: 4, content: 'ok', tool_name: 'bash', success: true)
      Messages::SystemEvent.create!(session: session, sequence: 5, content: 'done', event_type: 'complete')
    end

    it 'queries all messages through parent table' do
      expect(Message.where(session_id: session.id).count).to eq(5)
    end

    it 'queries only child table records' do
      expect(Messages::UserMessage.count).to eq(1)
      expect(Messages::AssistantResponse.count).to eq(1)
      expect(Messages::ToolInvocation.count).to eq(1)
    end

    it 'auto-instantiates correct subclasses from parent query' do
      messages = Message.where(session_id: session.id).order(:sequence)
      expect(messages[0]).to be_a(Messages::UserMessage)
      expect(messages[1]).to be_a(Messages::AssistantResponse)
      expect(messages[2]).to be_a(Messages::ToolInvocation)
      expect(messages[3]).to be_a(Messages::ToolResult)
      expect(messages[4]).to be_a(Messages::SystemEvent)
    end

    # Child-specific columns aren't available when querying through the parent
    # table — this is a PG inheritance limitation, not a gem bug. To access
    # child columns, query the child class directly or reload the record.
    it 'can access child-specific attributes after reload' do
      tool = Message.where(session_id: session.id).order(:sequence).third
      expect(tool).to be_a(Messages::ToolInvocation)
      tool.reload
      expect(tool.tool_name).to eq('bash')
    end
  end

  describe 'associations' do
    it 'resolves has_many through parent class' do
      Messages::UserMessage.create!(session: session, sequence: 1, content: 'Hello', role: 'user')
      Messages::AssistantResponse.create!(session: session, sequence: 2, content: 'Hi', model: 'claude-3', token_count: 10)

      expect(session.messages.count).to eq(2)
    end

    it 'discriminates types in association results' do
      Messages::UserMessage.create!(session: session, sequence: 1, content: 'Hello', role: 'user')
      Messages::AssistantResponse.create!(session: session, sequence: 2, content: 'Hi', model: 'claude-3', token_count: 10)

      messages = session.messages.order(:sequence)
      expect(messages.first).to be_a(Messages::UserMessage)
      expect(messages.last).to be_a(Messages::AssistantResponse)
    end
  end

  describe 'calculations' do
    before do
      3.times { |i| Messages::UserMessage.create!(session: session, sequence: i + 1, content: "msg#{i}", role: 'user') }
      2.times { |i| Messages::AssistantResponse.create!(session: session, sequence: i + 4, content: "resp#{i}", model: 'claude-3', token_count: 10) }
    end

    it 'counts correctly across parent table' do
      expect(Message.count).to eq(5)
    end

    it 'counts correctly for child tables' do
      expect(Messages::UserMessage.count).to eq(3)
      expect(Messages::AssistantResponse.count).to eq(2)
    end

    it 'supports grouped counts' do
      grouped = Messages::AssistantResponse.group(:model).count
      expect(grouped['claude-3']).to eq(2)
    end
  end

  describe 'destroy' do
    it 'destroys child records' do
      msg = Messages::UserMessage.create!(session: session, sequence: 1, content: 'Hello', role: 'user')
      expect(Message.count).to eq(1)
      msg.destroy!
      expect(Message.count).to eq(0)
    end
  end
end
