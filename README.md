# HeartVoice: AI-Powered Mental Health Support App

**HeartVoice** is a mental wellness app designed for young individuals and people with disabilities. By integrating emotion recognition, speech analysis, and intelligent feedback, it creates a lightweight yet empathetic digital space for emotional self-awareness, self-regulation, and long-term mental state tracking.

---

## 📌 Project Scope and Implementation

- Enables voice/text-based emotional journaling for better emotional expression.
- Applies NLP and physiological data (e.g., HRV) for emotion recognition.
- Provides personalized psychological suggestions (e.g., mindfulness, AI-guided conversations).
- Continuously tracks emotional trends and builds individual emotional profiles.
- Ensures local data encryption and strong user privacy protection.

---

## 🧩 User Requirements

| ID | Description | Priority | Notes |
|----|-------------|----------|-------|
| 1 | Allow users to record their emotions via voice or text. The system identifies emotion types (e.g., anxious, happy). | P0 | Integrate voice-to-text engine |
| 2 | Acquire HRV/heart rate data to enhance emotion analysis accuracy. | P0 | Integrate with HealthKit or wearable API |
| 3 | Generate personalized mental health advice based on detected emotional states. | P0 | Suggest cards, breathing, or mindfulness tips |
| 4 | Create user profiles based on initial input and continuous data tracking. | P1 | Enables adaptive recommendations |
| 5 | Visualize emotional trends by day/week/month. | P0 | Use Swift Charts or equivalent |
| 6 | All user data should be encrypted and stored locally. | P2 | Use AES with CoreData for storage |

---

## ⚙️ Functional Modules

| Module | Description |
|--------|-------------|
| User Interaction | Voice/text input interface with accessibility for visually impaired users |
| Emotion Recognition | NLP-based emotion classification (e.g., BERT) |
| Physiological Data Collection | HRV and heart rate integration |
| Emotion Feedback Generator | Matches suggestions based on real-time and historical data |
| User Profiling | Records and analyzes mood trends, builds emotional profiles |
| Data Visualization | Graphs for emotion trends, HRV overlays |
| Secure Data Storage | Local encrypted storage via CoreData |
| AI Emotion Assistant | Multi-turn conversations for emotional relief and guidance |

---

## 🔗 Core Logical Workflows

### 1. Emotion Capture and Recognition

```
User Input (Voice/Text/HRV)
   ↓
Speech-to-Text (Whisper) + NLP Parsing
   ↓
Emotion Classification (BERT/TextCNN) → Local Storage (CoreData)
```

📌 Modules: UI Layer, Speech/NLP Engine, Database  
📌 Tech Stack: Whisper, BERT, HRV Sensor APIs

---

### 2. Emotion Feedback and Suggestion Flow

```
Emotion + History + HRV
   ↓
Context-Aware Analysis
   ↓
Suggestion Engine → Mindfulness, Breathing, AI Chat
   ↓
Output Display to App Frontend
```

📌 Modules: Suggestion Engine, Knowledge Base  
📌 Techniques: Context Matching, RAG, User Feedback Integration

---

### 3. Profile Building and Trend Tracking

```
Emotion Records + Feedback
   ↓
Trend Charts (Daily/Weekly/Monthly)
   ↓
Profile Update → Adaptive Recommendation Loop
```

📌 Modules: Profile Engine, Chart System  
📌 Techniques: Labeling, Trend Clustering, Swift Charts

---

### 4. Emotional Trend Visualization

```
Data Sources: Emotion + HRV + Feedback
   ↓
Aggregation & Analysis
   ↓
Dynamic Graphs (Line, Heatmap)
   ↓
Frontend Visualization with Filters
```

📌 Tools: CoreData Queries, Swift Charts/Charts-iOS  
📌 Focus: Real-time updates, multi-layered emotion mapping

---

## 🛡️ Tech Stack Suggestions

- Frontend: Swift (iOS Native)
- Storage: CoreData + AES Encryption
- Visualization: Swift Charts / Charts-iOS
- Speech Recognition: Apple Speech / Whisper API
- NLP Models: BERT / TextCNN / FastText
- AI Dialogues: OpenAI / Dify / Claude APIs

---

## 📍Future Extensions

- Multi-language emotion support (Mandarin, English, dialects)
- Institutional backend for monitoring students' mental health
- Referral system to certified counseling services
- Exportable PDF reports for professional use

---

> 🧠 *HeartVoice is not just an app — it's your silent companion for emotional well-being.*
