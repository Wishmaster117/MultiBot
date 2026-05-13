<div align="center">

# ⚠️ MultiBot is Deprecated ⚠️

### This repository is no longer the recommended installation source.

<br>

<strong>The project has been split into two dedicated repositories:</strong>

<br><br>

<table>
  <tr>
    <th>Component</th>
    <th>Repository</th>
    <th>Purpose</th>
  </tr>
  <tr>
    <td><strong>Client Addon</strong></td>
    <td>
      <a href="https://github.com/Wishmaster117/MultiBot-Chatless">
        Wishmaster117/MultiBot-Chatless
      </a>
    </td>
    <td>
      World of Warcraft client addon installed in <code>Interface/AddOns</code>
    </td>
  </tr>
  <tr>
    <td><strong>AzerothCore Module</strong></td>
    <td>
      <a href="https://github.com/Wishmaster117/mod-multibot-bridge">
        Wishmaster117/mod-multibot-bridge
      </a>
    </td>
    <td>
      Server-side bridge module installed in the AzerothCore <code>modules</code> directory
    </td>
  </tr>
</table>

<br>

<strong>Do not use this repository for new installations.</strong>

</div>

---

## 📌 What happened?

`MultiBot-Standalone`  was originally built around Playerbots chat parsing.

In this first version, the addon communicates with bots by sending commands through the normal in-game chat system, then reads and parses the bot replies to update the UI.

This approach works, but it has a major drawback: many bot actions generate visible chat messages, which can quickly become noisy when controlling several bots.

For this reason, I later started experimenting with a bridge-based version of MultiBot, where an AzerothCore module handles communication with Playerbots more directly. The goal of that approach is to reduce visible chat spam and make bot interactions cleaner for the user.

This repository remains the original chat-parsing version of MultiBot.

---

# ✅ New Installation Method

## 1. Install the client addon

Use this repository:

<div align="center">

### 👉 [MultiBot-Chatless](https://github.com/Wishmaster117/MultiBot-Chatless)

</div>

Clone it into your World of Warcraft addon directory.

```bash
cd "World of Warcraft/Interface/AddOns"
git clone https://github.com/Wishmaster117/MultiBot-Chatless.git MultiBot
```

The final folder structure must look like this:

```text
World of Warcraft/
└── Interface/
    └── AddOns/
        └── MultiBot/
            ├── MultiBot.toc
            ├── Core/
            ├── UI/
            ├── Locales/
            └── ...
```

> Important: the repository is named `MultiBot-Chatless`, but the local addon folder must be named `MultiBot`.

---

## 2. Install the AzerothCore bridge module

Use this repository:

<div align="center">

### 👉 [mod-multibot-bridge](https://github.com/Wishmaster117/mod-multibot-bridge)

</div>

Clone it into your AzerothCore `modules` directory.

```bash
cd /path/to/azerothcore/modules
git clone https://github.com/Wishmaster117/mod-multibot-bridge.git mod-multibot-bridge
```

The final folder structure must look like this:

```text
azerothcore/
└── modules/
    └── mod-multibot-bridge/
        ├── conf/
        └── src/
```

After installing the module, re-run CMake and rebuild your AzerothCore server.

---

# 🔄 Updating

## Update the addon

```bash
cd "World of Warcraft/Interface/AddOns/MultiBot"
git pull
```

## Update the AzerothCore module

```bash
cd /path/to/azerothcore/modules/mod-multibot-bridge
git pull
```

Then rebuild your AzerothCore server if the module code changed.

---

# 🧩 Repository Split Summary

| Old repository | Status |
|---|---|
| `Wishmaster117/MultiBot-Standalone` | Deprecated / legacy combined repository |

| New repository | Usage |
|---|---|
| `Wishmaster117/MultiBot-Chatless` | Client addon |
| `Wishmaster117/mod-multibot-bridge` | AzerothCore bridge module |

---

# ⚠️ For Existing Users

If you previously cloned this repository directly, it is recommended to switch to the new split repositories.

Remove the old addon folder and install the new addon repository:

```bash
cd "World of Warcraft/Interface/AddOns"
rm -rf MultiBot
git clone https://github.com/Wishmaster117/MultiBot-Chatless.git MultiBot
```

For the server module:

```bash
cd /path/to/azerothcore/modules
rm -rf mod-multibot-bridge
git clone https://github.com/Wishmaster117/mod-multibot-bridge.git mod-multibot-bridge
```

Then re-run CMake and rebuild AzerothCore.

---

# ❌ This Repository Will No Longer Be the Main Update Target

Future active development should happen in:

- [MultiBot-Chatless](https://github.com/Wishmaster117/MultiBot-Chatless)
- [mod-multibot-bridge](https://github.com/Wishmaster117/mod-multibot-bridge)

This repository may remain available for reference, history, or archival purposes only.

---

<div align="center">

## ✅ Please use the new repositories

### Client Addon

<a href="https://github.com/Wishmaster117/MultiBot-Chatless">
  https://github.com/Wishmaster117/MultiBot-Chatless
</a>

<br><br>

### AzerothCore Bridge Module

<a href="https://github.com/Wishmaster117/mod-multibot-bridge">
  https://github.com/Wishmaster117/mod-multibot-bridge
</a>

</div>
