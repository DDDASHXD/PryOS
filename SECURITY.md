# Security and recovery boundaries

PryOS intentionally autologs into a local root XFCE session. AI terminals run as root and passwordless sudo is configured. Root commands can permanently change attached drives and firmware settings. The nonpersistent OS overlay does not undo those changes. The image is a recovery tool, not a hardened general-purpose daily desktop.

Helium launches as a dedicated, password-locked `pryos-browser` account with Chromium's sandbox enabled. Root authorizes that local X11 identity without prompting. It does not use `--no-sandbox` or permit all X11 clients. X11 itself does not isolate desktop applications from each other as strongly as a separate graphical session would.

The launcher loads Helium's packaged AppArmor user-namespace profile in the live kernel when AppArmor is enabled. It does not disable Ubuntu's restriction globally. Chromium uses the basic password store to avoid a keyring password dialog in the passwordless live session; the browser profile is temporary and is not protected by a separate encrypted desktop keyring.

Agent permission/trust controls and Linux password authentication are different. Codex has full filesystem access with on-request approval policy; other agents keep their own controls. The recovery instructions request approval for destructive repairs. These instructions are guidance, not a security boundary against malicious model behavior.

No accounts or keys are baked in. Live credentials and browser profiles are temporary unless the user configures persistence. Automatic disk mounting is disabled, but manually mounting or repairing disks remains possible. Use only on systems you are authorized to administer.

Do not file public issues containing passwords, access tokens, registry contents, recovery keys, private disk images or personal logs. For sensitive project vulnerabilities use GitHub's private vulnerability reporting if available on the repository. If it is unavailable, open a minimal issue asking for a private reporting channel without posting exploit details or sensitive data.
