const chat = document.getElementById("chat");
const form = document.getElementById("chat-form");
const messageInput = document.getElementById("message");
const sendBtn = document.getElementById("send-btn");
const template = document.getElementById("message-template");

function appendMessage(role, content) {
  const node = template.content.cloneNode(true);
  const wrapper = node.querySelector(".message");
  const roleEl = node.querySelector(".role");
  const contentEl = node.querySelector(".content");

  wrapper.classList.add(role === "user" ? "user" : "assistant");
  roleEl.textContent = role === "user" ? "You" : "Assistant";
  contentEl.textContent = content;

  chat.appendChild(node);
  chat.scrollTop = chat.scrollHeight;
}

async function sendMessage(message) {
  const response = await fetch("/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message }),
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(body.error || "Unknown error");
  }

  return body.reply;
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const message = messageInput.value.trim();
  if (!message) return;

  appendMessage("user", message);
  messageInput.value = "";
  sendBtn.disabled = true;

  try {
    const reply = await sendMessage(message);
    appendMessage("assistant", reply);
  } catch (error) {
    appendMessage("assistant", `Error: ${error.message}`);
  } finally {
    sendBtn.disabled = false;
    messageInput.focus();
  }
});
