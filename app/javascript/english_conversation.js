// English Conversation Practice - Turbo Compatible Version
console.log('English conversation script loaded at:', new Date().toISOString());

// Wait for page to be ready - handle both regular load and Turbo
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', setupPage);
} else {
  // DOM is already loaded
  setupPage();
}

// Also listen for Turbo events
document.addEventListener('turbo:load', () => {
  console.log('Turbo:load event');
  isSetup = false; // Reset flag
  setupPage();
});

document.addEventListener('turbo:render', () => {
  console.log('Turbo:render event');
  setupPage();
});

// Clean up before caching
document.addEventListener('turbo:before-cache', () => {
  console.log('Turbo:before-cache - cleaning up');
  if (recognition && isRecording) {
    recognition.stop();
  }
  isSetup = false;
});

// Global variables
let recognition = null;
let isRecording = false;
let currentSituation = null;
let currentLanguage = 'en';
let currentMode = 'voice';
let finalTranscript = '';
let pendingSituationCard = null;
let isSetup = false;

function setupPage() {
  console.log('Setting up page at:', new Date().toISOString());
  
  // Check if we're on the conversation page
  const container = document.querySelector('.english-conversation-container');
  if (!container) {
    console.log('Not on conversation page');
    isSetup = false;
    return;
  }
  
  // Reset setup flag for new page loads
  if (isSetup) {
    console.log('Already set up, resetting...');
  }
  isSetup = true;
  
  console.log('On conversation page, initializing...');
  
  // Setup speech recognition
  setupSpeechRecognition();
  
  // Setup all event listeners
  setupListeners();
  
  // Set initial language to English
  switchLanguage('en');
  
  // Set initial mode
  switchToVoiceMode();
  
  console.log('Setup complete');
}

function setupSpeechRecognition() {
  const browserNotice = document.getElementById('browser-notice');
  const micButton = document.getElementById('mic-button');
  
  if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
    if (browserNotice) browserNotice.classList.remove('hidden');
    if (micButton) {
      micButton.disabled = true;
      micButton.style.opacity = '0.5';
    }
    return;
  }
  
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  recognition = new SpeechRecognition();
  
  recognition.continuous = true;
  recognition.interimResults = true;
  recognition.lang = 'en-US';
  
  recognition.onstart = function() {
    isRecording = true;
    finalTranscript = '';
    const micButton = document.getElementById('mic-button');
    const statusMessage = document.getElementById('status-message');
    const currentTranscript = document.getElementById('current-transcript');
    
    if (micButton) micButton.classList.add('recording');
    if (statusMessage) statusMessage.textContent = getLocalizedText('listening');
    if (currentTranscript) currentTranscript.classList.remove('hidden');
  };
  
  recognition.onend = function() {
    isRecording = false;
    const micButton = document.getElementById('mic-button');
    const statusMessage = document.getElementById('status-message');
    const currentTranscript = document.getElementById('current-transcript');
    
    if (micButton) micButton.classList.remove('recording');
    if (statusMessage) statusMessage.textContent = '';
    if (currentTranscript) currentTranscript.classList.add('hidden');
    
    if (finalTranscript) {
      processUserInput(finalTranscript);
    }
  };
  
  recognition.onerror = function(event) {
    console.error('Speech error:', event.error);
    isRecording = false;
    const micButton = document.getElementById('mic-button');
    const statusMessage = document.getElementById('status-message');
    
    if (micButton) micButton.classList.remove('recording');
    if (statusMessage) {
      statusMessage.textContent = getLocalizedText('error') + event.error;
      setTimeout(() => { statusMessage.textContent = ''; }, 3000);
    }
  };
  
  recognition.onresult = function(event) {
    let interimTranscript = '';
    
    for (let i = event.resultIndex; i < event.results.length; i++) {
      const transcript = event.results[i][0].transcript;
      if (event.results[i].isFinal) {
        finalTranscript += transcript + ' ';
      } else {
        interimTranscript += transcript;
      }
    }
    
    const transcriptText = document.getElementById('transcript-text');
    if (transcriptText) {
      transcriptText.textContent = finalTranscript + interimTranscript;
    }
  };
}

function setupListeners() {
  console.log('Setting up listeners');
  
  // Remove all existing listeners first by cloning nodes
  removeAllListeners();
  
  // Mic button
  const micButton = document.getElementById('mic-button');
  if (micButton) {
    console.log('Mic button found');
    micButton.addEventListener('click', function(e) {
      e.preventDefault();
      console.log('Mic button clicked');
      toggleRecording();
    });
  }
  
  // Clear buttons
  const clearButton = document.getElementById('clear-button');
  if (clearButton) {
    clearButton.addEventListener('click', function(e) {
      e.preventDefault();
      showClearModal();
    });
  }
  
  const clearButtonText = document.getElementById('clear-button-text');
  if (clearButtonText) {
    clearButtonText.addEventListener('click', function(e) {
      e.preventDefault();
      showClearModal();
    });
  }
  
  // Send button
  const sendButton = document.getElementById('send-button');
  if (sendButton) {
    sendButton.addEventListener('click', function(e) {
      e.preventDefault();
      sendTextMessage();
    });
  }
  
  // Text input
  const textInput = document.getElementById('text-input');
  if (textInput) {
    textInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendTextMessage();
      }
    });
  }
  
  // Mode buttons
  const voiceMode = document.getElementById('voice-mode');
  if (voiceMode) {
    voiceMode.addEventListener('click', function(e) {
      e.preventDefault();
      switchToVoiceMode();
    });
  }
  
  const silentMode = document.getElementById('silent-mode');
  if (silentMode) {
    silentMode.addEventListener('click', function(e) {
      e.preventDefault();
      switchToSilentMode();
    });
  }
  
  // Language buttons
  const langEn = document.getElementById('lang-en');
  if (langEn) {
    langEn.addEventListener('click', function(e) {
      e.preventDefault();
      switchLanguage('en');
    });
  }
  
  const langJa = document.getElementById('lang-ja');
  if (langJa) {
    langJa.addEventListener('click', function(e) {
      e.preventDefault();
      switchLanguage('ja');
    });
  }
  
  // Situation cards
  document.querySelectorAll('.situation-card').forEach(card => {
    card.addEventListener('click', function(e) {
      e.preventDefault();
      handleSituationClick(this);
    });
  });
  
  // Modal buttons
  const modalCancel = document.getElementById('modal-cancel');
  if (modalCancel) {
    modalCancel.addEventListener('click', function(e) {
      e.preventDefault();
      hideConfirmationModal();
      pendingSituationCard = null;
    });
  }
  
  const modalConfirm = document.getElementById('modal-confirm');
  if (modalConfirm) {
    modalConfirm.addEventListener('click', function(e) {
      e.preventDefault();
      handleModalConfirm();
    });
  }
  
  const clearCancel = document.getElementById('clear-cancel');
  if (clearCancel) {
    clearCancel.addEventListener('click', function(e) {
      e.preventDefault();
      hideClearModal();
    });
  }
  
  const clearConfirm = document.getElementById('clear-confirm');
  if (clearConfirm) {
    clearConfirm.addEventListener('click', function(e) {
      e.preventDefault();
      clearConversationHistory();
      hideClearModal();
    });
  }
  
  // Modal backgrounds
  const confirmationModal = document.getElementById('confirmation-modal');
  if (confirmationModal) {
    confirmationModal.addEventListener('click', function(e) {
      if (e.target === this) {
        hideConfirmationModal();
        pendingSituationCard = null;
      }
    });
  }
  
  const clearModal = document.getElementById('clear-modal');
  if (clearModal) {
    clearModal.addEventListener('click', function(e) {
      if (e.target === this) {
        hideClearModal();
      }
    });
  }
  
  console.log('All listeners set up');
}

function removeAllListeners() {
  // Clone and replace elements to remove all event listeners
  const elementsToClean = [
    'mic-button', 'clear-button', 'clear-button-text', 'send-button',
    'voice-mode', 'silent-mode', 'lang-en', 'lang-ja',
    'modal-cancel', 'modal-confirm', 'clear-cancel', 'clear-confirm',
    'confirmation-modal', 'clear-modal'
  ];
  
  elementsToClean.forEach(id => {
    const element = document.getElementById(id);
    if (element) {
      const newElement = element.cloneNode(true);
      element.parentNode.replaceChild(newElement, element);
    }
  });
  
  // Also clean situation cards
  document.querySelectorAll('.situation-card').forEach(card => {
    const newCard = card.cloneNode(true);
    card.parentNode.replaceChild(newCard, card);
  });
}

// All other functions remain the same...
function toggleRecording() {
  if (!recognition) {
    console.log('Recognition not ready');
    return;
  }
  
  if (isRecording) {
    recognition.stop();
  } else {
    recognition.start();
  }
}

function handleSituationClick(card) {
  if (card.classList.contains('active')) {
    return;
  }
  
  pendingSituationCard = card;
  
  const conversationHistory = document.getElementById('conversation-history');
  const hasConversation = conversationHistory && conversationHistory.querySelector('.message-pair');
  const hasSituation = currentSituation !== null;
  
  if (hasConversation || hasSituation) {
    showConfirmationModal();
  } else {
    showConfirmationModal();
  }
}

function handleModalConfirm() {
  if (pendingSituationCard) {
    const selectedModeRadio = document.querySelector('input[name="modal-mode"]:checked');
    const selectedMode = selectedModeRadio ? selectedModeRadio.value : 'voice';
    
    switchSituation(pendingSituationCard, selectedMode);
    pendingSituationCard = null;
  }
  hideConfirmationModal();
}

async function switchSituation(card, selectedMode) {
  document.querySelectorAll('.situation-card').forEach(c => c.classList.remove('active'));
  card.classList.add('active');
  
  currentSituation = card.dataset.situation;
  
  const currentSituationText = document.getElementById('current-situation-text');
  if (currentSituationText) {
    const cardTitle = card.querySelector('.card-title');
    if (cardTitle) {
      currentSituationText.textContent = cardTitle.textContent;
    }
  }
  
  if (selectedMode === 'voice') {
    switchToVoiceMode();
  } else if (selectedMode === 'silent') {
    switchToSilentMode();
  }
  
  await clearConversationHistory(false);
  await getInitialMessage(currentSituation);
}

function switchToVoiceMode() {
  currentMode = 'voice';
  const voiceModeBtn = document.getElementById('voice-mode');
  const silentModeBtn = document.getElementById('silent-mode');
  const voiceControls = document.getElementById('voice-controls');
  const textControls = document.getElementById('text-controls');
  
  if (voiceModeBtn) voiceModeBtn.classList.add('active');
  if (silentModeBtn) silentModeBtn.classList.remove('active');
  if (voiceControls) voiceControls.classList.remove('hidden');
  if (textControls) textControls.classList.add('hidden');
}

function switchToSilentMode() {
  currentMode = 'silent';
  const silentModeBtn = document.getElementById('silent-mode');
  const voiceModeBtn = document.getElementById('voice-mode');
  const textControls = document.getElementById('text-controls');
  const voiceControls = document.getElementById('voice-controls');
  
  if (silentModeBtn) silentModeBtn.classList.add('active');
  if (voiceModeBtn) voiceModeBtn.classList.remove('active');
  if (textControls) textControls.classList.remove('hidden');
  if (voiceControls) voiceControls.classList.add('hidden');
  
  if (isRecording && recognition) {
    recognition.stop();
  }
}

function switchLanguage(lang) {
  currentLanguage = lang;
  
  const langEnBtn = document.getElementById('lang-en');
  const langJaBtn = document.getElementById('lang-ja');
  
  if (lang === 'en') {
    if (langEnBtn) langEnBtn.classList.add('active');
    if (langJaBtn) langJaBtn.classList.remove('active');
  } else {
    if (langEnBtn) langEnBtn.classList.remove('active');
    if (langJaBtn) langJaBtn.classList.add('active');
  }
  
  document.querySelectorAll('[data-en][data-ja]').forEach(element => {
    const text = element.getAttribute(`data-${lang}`);
    if (text) element.textContent = text;
  });
  
  const textInput = document.getElementById('text-input');
  if (textInput) {
    const placeholderText = lang === 'en' 
      ? textInput.getAttribute('data-placeholder-en')
      : textInput.getAttribute('data-placeholder-ja');
    if (placeholderText) {
      textInput.placeholder = placeholderText;
    }
  }
}

async function sendTextMessage() {
  const textInput = document.getElementById('text-input');
  if (!textInput) return;
  
  const text = textInput.value.trim();
  if (!text) return;
  
  textInput.value = '';
  await processUserInput(text);
}

async function processUserInput(text) {
  const statusMessage = document.getElementById('status-message');
  if (statusMessage) statusMessage.textContent = getLocalizedText('processing');
  
  const userMessagePair = addMessageToUI('user', text);
  
  try {
    const response = await fetch('/english_conversation/speech', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ 
        text: text,
        situation: currentSituation 
      })
    });
    
    if (!response.ok) throw new Error('Network error');
    
    const data = await response.json();
    
    if (data.response && data.response.includes('I\'m having trouble')) {
      if (userMessagePair) userMessagePair.remove();
      if (statusMessage) {
        statusMessage.textContent = data.response;
        setTimeout(() => { statusMessage.textContent = ''; }, 3000);
      }
    } else {
      addMessageToUI('assistant', data.response, userMessagePair);
      await playAudioResponse(data.response);
    }
    
    if (statusMessage) statusMessage.textContent = '';
  } catch (error) {
    console.error('Error:', error);
    if (userMessagePair) userMessagePair.remove();
    if (statusMessage) {
      statusMessage.textContent = 'Error processing request';
      setTimeout(() => { statusMessage.textContent = ''; }, 3000);
    }
  }
}

function addMessageToUI(role, text, existingPair = null) {
  const conversationHistory = document.getElementById('conversation-history');
  if (!conversationHistory) return null;
  
  if (role === 'user') {
    const messagePair = document.createElement('div');
    messagePair.className = 'message-pair';
    messagePair.innerHTML = `
      <div class="user-message">
        <span class="message-label user-label">You:</span>
        <span class="message-text">${escapeHtml(text)}</span>
      </div>
    `;
    
    const welcomeMessage = conversationHistory.querySelector('.welcome-message');
    if (welcomeMessage) welcomeMessage.remove();
    
    conversationHistory.appendChild(messagePair);
    scrollToBottom();
    
    return messagePair;
  } else {
    if (existingPair) {
      existingPair.innerHTML += `
        <div class="assistant-message">
          <span class="message-label assistant-label">Tutor:</span>
          <span class="message-text">${escapeHtml(text)}</span>
        </div>
      `;
    }
    scrollToBottom();
  }
}

async function playAudioResponse(text) {
  if (currentMode === 'silent') {
    const soundEnabled = document.getElementById('sound-enabled');
    if (soundEnabled && !soundEnabled.checked) return;
  }
  
  try {
    const response = await fetch('/english_conversation/tts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ text: text })
    });
    
    if (!response.ok) throw new Error('TTS error');
    
    const data = await response.json();
    
    if (data.audio) {
      const audio = new Audio('data:audio/mp3;base64,' + data.audio);
      audio.play().catch(e => console.error('Audio play error:', e));
    }
  } catch (error) {
    console.error('TTS error:', error);
  }
}

async function clearConversationHistory(showWelcome = true) {
  const conversationHistory = document.getElementById('conversation-history');
  if (!conversationHistory) return;
  
  if (showWelcome) {
    const welcomeTitle = getLocalizedText('welcomeTitle');
    const welcomeSubtitle = getLocalizedText('welcomeSubtitle');
    
    conversationHistory.innerHTML = `
      <div class="welcome-message">
        <p class="welcome-title" data-en="Welcome to English Conversation Practice!" data-ja="英会話練習へようこそ！">${welcomeTitle}</p>
        <p class="welcome-subtitle" data-en="Please select a situation above to begin your practice." data-ja="上記からシチュエーションを選択して練習を始めてください。">${welcomeSubtitle}</p>
      </div>
    `;
  } else {
    conversationHistory.innerHTML = '';
  }
  
  try {
    await fetch('/english_conversation/clear', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    });
  } catch (error) {
    console.error('Clear session error:', error);
  }
}

async function getInitialMessage(situation) {
  const statusMessage = document.getElementById('status-message');
  const conversationHistory = document.getElementById('conversation-history');
  
  try {
    if (statusMessage) statusMessage.textContent = getLocalizedText('processing');
    
    const response = await fetch('/english_conversation/initial', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ situation: situation })
    });
    
    if (!response.ok) throw new Error('Network error');
    
    const data = await response.json();
    
    if (conversationHistory) {
      conversationHistory.innerHTML = '';
      
      const messagePair = document.createElement('div');
      messagePair.className = 'message-pair';
      messagePair.innerHTML = `
        <div class="assistant-message">
          <span class="message-label assistant-label">Tutor:</span>
          <span class="message-text">${escapeHtml(data.response)}</span>
        </div>
      `;
      conversationHistory.appendChild(messagePair);
      scrollToBottom();
    }
    
    await playAudioResponse(data.response);
    
    if (statusMessage) statusMessage.textContent = '';
  } catch (error) {
    console.error('Initial message error:', error);
    if (statusMessage) statusMessage.textContent = '';
  }
}

function showConfirmationModal() {
  const modal = document.getElementById('confirmation-modal');
  if (modal) {
    const modeRadios = document.querySelectorAll('input[name="modal-mode"]');
    modeRadios.forEach(radio => {
      radio.checked = radio.value === currentMode;
    });
    modal.classList.remove('hidden');
  }
}

function hideConfirmationModal() {
  const modal = document.getElementById('confirmation-modal');
  if (modal) modal.classList.add('hidden');
}

function showClearModal() {
  const modal = document.getElementById('clear-modal');
  if (modal) modal.classList.remove('hidden');
}

function hideClearModal() {
  const modal = document.getElementById('clear-modal');
  if (modal) modal.classList.add('hidden');
}

function getLocalizedText(key) {
  const messages = {
    en: {
      listening: 'Listening... Speak now',
      processing: 'Processing...',
      error: 'Error: ',
      welcomeTitle: 'Welcome to English Conversation Practice!',
      welcomeSubtitle: 'Please select a situation above to begin your practice.'
    },
    ja: {
      listening: '聞いています... 話してください',
      processing: '処理中...',
      error: 'エラー: ',
      welcomeTitle: '英会話練習へようこそ！',
      welcomeSubtitle: '上記からシチュエーションを選択して練習を始めてください。'
    }
  };
  
  return messages[currentLanguage]?.[key] || messages.en[key];
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function scrollToBottom() {
  const conversationArea = document.getElementById('conversation-area');
  if (conversationArea) {
    conversationArea.scrollTop = conversationArea.scrollHeight;
  }
}