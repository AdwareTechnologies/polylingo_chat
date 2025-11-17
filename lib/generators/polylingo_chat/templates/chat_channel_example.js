import consumer from "@rails/actioncable"

const cable = consumer.createConsumer();

export default function subscribe(conversationId, handleReceive) {
  const subscription = cable.subscriptions.create({ channel: 'PolylinguoChatChannel', conversation_id: conversationId }, {
    connected() {},
    disconnected() {},
    received(data) {
      handleReceive(data)
    },
    sendMessage(text, conversationId) {
      this.perform('receive', { message: text, conversation_id: conversationId });
    }
  });

  return subscription;
}
