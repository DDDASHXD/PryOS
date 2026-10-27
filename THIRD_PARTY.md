# Third-party software

The MIT license covers PryOS's original build scripts, configuration, documentation and SVG artwork. It does **not** relicense Ubuntu, XFCE, Helium, the recovery utilities, Node.js, or any agent client.

The source repository contains build instructions and configuration, not third-party application binaries or a vendored Ubuntu filesystem. The build downloads packages from their respective publishers. Their license files, package metadata and attribution remain in the image; `/usr/share/doc` is retained.

| Component | Source and licensing information |
| --- | --- |
| Ubuntu packages and kernel | [Ubuntu licensing](https://ubuntu.com/legal/intellectual-property-policy); package-specific copyright/license files in `/usr/share/doc` |
| XFCE | [XFCE about/licensing](https://www.xfce.org/about) and package-specific notices |
| Helium | [imputnet/helium](https://github.com/imputnet/helium), [Linux packaging](https://github.com/imputnet/helium-linux); upstream includes GPL/BSD and third-party notices |
| Node.js | [Node license](https://github.com/nodejs/node/blob/main/LICENSE) |
| Codex | [OpenAI Codex](https://github.com/openai/codex); installed standalone package's terms/notices apply |
| Claude Code | [Anthropic Claude Code](https://code.claude.com/docs/en/legal-and-compliance); proprietary client terms apply |
| Gemini CLI | [Google Gemini CLI](https://github.com/google-gemini/gemini-cli) |
| OpenCode | [OpenCode](https://github.com/anomalyco/opencode) |

Agent use requires your own provider access. No subscription, API key or model weights are included. Before redistributing a built ISO, review the included versions' licenses, source-availability obligations and vendor redistribution terms. Publishing this repository is not a grant to redistribute every downloaded binary under MIT.

The public Helium repository signing key is in `payload/keys/helium.asc`, obtained from upstream's `pubkey.asc`. Its expected primary fingerprint is `BE677C1989D35EAB2C5F26C9351601AD01D6378E`. Key rotation is an explicit source change.
