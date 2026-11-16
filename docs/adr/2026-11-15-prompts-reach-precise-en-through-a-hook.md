# Prompts reach precise-en through a prompt hook, not a skill

## Decision

- Claude Code and Codex hand every prompt to `precise-en` through their UserPromptSubmit hook. There is no agent skill.
- The hook returns at once and prints nothing. Long prompts go to a detached process that asks the background agent configured in tmux-agent-plane for the word, through `tmux-agent-plane background`, and saves it.
- Only long prompts are looked at; short ones carry too little of Alex's writing to improve.
- The background agent's answer is checked before saving: the phrase it quotes must be in the prompt and the word must not be. Duplicates are refused by the store and also listed in the request so the agent avoids them.

## Why

Alex wants it automatic on every long prompt without slowing the agent he is talking to. A skill loads only when an agent judges it relevant and would spend the working agent's context and turns. A hook fires on every prompt, costs the working agent nothing, and one cheap background model is already configured on this Mac for naming and cleanup.

## Rejected

- **An agent skill that starts a subagent.** Not reliable on every prompt, and it runs inside the working agent's turn.
- **Running a model CLI directly (Haiku, Luna).** Alex chose the tmux-agent-plane background agent so one setting picks the cheap model for every background job.
- **Reading tmux-agent-plane's config file from precise-en.** It would duplicate the command transport; `tmux-agent-plane background` is the one way to run that agent.
