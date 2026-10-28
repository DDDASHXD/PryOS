from pathlib import Path
import subprocess

versions = []
for tool in ('codex', 'claude', 'gemini', 'opencode', 'node'):
    versions.append(f'{tool}: ' + subprocess.check_output([tool, '--version'], text=True).strip())
Path('/opt/recovery/ai-versions.txt').write_text('\n'.join(versions) + '\n')

settings = Path('/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml')
settings.mkdir(parents=True, exist_ok=True)
# The factory layout adds a second short panel of launchers. Keep the top bar only.
panel_xml = '''<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="mode" type="uint" value="0"/>
      <property name="icon-size" type="uint" value="16"/>
      <property name="size" type="uint" value="26"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="8"/>
        <value type="int" value="9"/>
        <value type="int" value="10"/>
        <value type="int" value="11"/>
        <value type="int" value="12"/>
        <value type="int" value="13"/>
        <value type="int" value="14"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-icon" type="string" value="/usr/share/icons/hicolor/scalable/apps/pryos-menu.svg"/>
      <property name="button-title" type="string" value="Applications"/>
    </property>
    <property name="plugin-2" type="string" value="tasklist">
      <property name="grouping" type="uint" value="1"/>
    </property>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-5" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-6" type="string" value="systray">
      <property name="square-icons" type="bool" value="true"/>
    </property>
    <property name="plugin-8" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
      <property name="show-notifications" type="bool" value="true"/>
    </property>
    <property name="plugin-9" type="string" value="power-manager-plugin"/>
    <property name="plugin-10" type="string" value="notification-plugin"/>
    <property name="plugin-11" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-12" type="string" value="clock"/>
    <property name="plugin-13" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-14" type="string" value="actions"/>
  </property>
</channel>
'''
(settings / 'xfce4-panel.xml').write_text(panel_xml)
Path('/etc/xdg/xfce4/panel').mkdir(parents=True, exist_ok=True)
Path('/etc/xdg/xfce4/panel/default.xml').write_text(panel_xml)
(settings / 'xfwm4.xml').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>
''')
(settings / 'thunar-volman.xml').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<channel name="thunar-volman" version="1.0">
<property name="automount-drives" type="empty"><property name="enabled" type="bool" value="false"/></property>
<property name="automount-media" type="empty"><property name="enabled" type="bool" value="false"/></property>
<property name="autobrowse" type="empty"><property name="enabled" type="bool" value="false"/></property>
</channel>
''')
(settings / 'xsettings.xml').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="IconThemeName" type="string" value="Yaru-dark"/>
  </property>
</channel>
''')
(settings / 'xfce4-desktop.xml').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
<property name="backdrop" type="empty">
<property name="screen0" type="empty">
<property name="monitor0" type="empty">
<property name="workspace0" type="empty">
<property name="color-style" type="int" value="0"/>
<property name="image-style" type="int" value="5"/>
<property name="last-image" type="string" value="/usr/share/backgrounds/pryos.jpg"/>
</property>
</property>
</property>
</property>
<property name="desktop-icons" type="empty">
<property name="style" type="int" value="2"/><property name="icon-size" type="uint" value="40"/>
<property name="file-icons" type="empty"><property name="show-home" type="bool" value="false"/><property name="show-trash" type="bool" value="false"/><property name="show-filesystem" type="bool" value="false"/></property>
</property></channel>
''')
(Path('/etc/skel/.config/xfce4') / 'helpers.rc').write_text('WebBrowser=pryos-helium\nTerminalEmulator=xfce4-terminal\nFileManager=Thunar\n')

desktop_root = Path('/etc/skel/Desktop')
apps = Path('/usr/share/applications')
desktop_root.mkdir(parents=True, exist_ok=True)
apps.mkdir(parents=True, exist_ok=True)
for stale in apps.glob('recovery-[0-9]*.desktop'):
    stale.unlink()
entries = [
    ('agents', 'Codex', 'pryos-codex', 'Codex', 'recovery-agent codex', 'utilities-terminal', True),
    ('agents', 'Claude Code', 'pryos-claude', 'Claude Code', 'recovery-agent claude', 'utilities-terminal', True),
    ('agents', 'Gemini CLI', 'pryos-gemini', 'Gemini CLI', 'recovery-agent gemini', 'utilities-terminal', True),
    ('agents', 'OpenCode', 'pryos-opencode', 'OpenCode', 'recovery-agent opencode', 'utilities-terminal', True),
    ('disks', 'GParted', 'pryos-gparted', 'GParted', 'gparted', 'gparted', False),
    ('disks', 'TestDisk', 'pryos-testdisk', 'TestDisk', 'recovery-tool testdisk', 'drive-harddisk', True),
    ('disks', 'PhotoRec', 'pryos-photorec', 'PhotoRec', 'recovery-tool photorec', 'camera-photo', True),
    ('disks', 'Disk Health', 'pryos-disk-health', 'Disk Health', 'gsmartcontrol', 'gsmartcontrol', False),
    ('disks', 'Disks', 'pryos-disks', 'Disks', 'gnome-disks', 'gnome-disks', False),
    ('disks', 'NTFS Utilities', 'pryos-ntfs', 'NTFS Utilities', 'recovery-tool ntfs', 'drive-harddisk', True),
    ('disks', 'Disk Imaging', 'pryos-ddrescue', 'Disk Imaging', 'recovery-tool ddrescue', 'drive-harddisk', True),
    ('disks', 'NVMe Inventory', 'pryos-nvme', 'NVMe Inventory', 'recovery-tool nvme', 'drive-harddisk', True),
    ('windows', 'Inspect Windows', 'pryos-windows', 'Inspect Windows', 'recovery-tool windows', 'drive-harddisk', True),
    ('windows', 'EFI Boot Entries', 'pryos-efi', 'EFI Boot Entries', 'recovery-tool efi', 'computer', True),
    ('windows', 'Windows Accounts', 'pryos-accounts', 'Windows Accounts', 'recovery-tool passwords', 'dialog-password', True),
    ('system', 'Root Terminal', 'pryos-terminal', 'Root Terminal', 'xfce4-terminal --default-working-directory=/root/Recovery', 'org.xfce.terminal', False),
    ('system', 'System Inventory', 'pryos-inventory', 'System Inventory', 'recovery-tool inventory', 'computer', True),
    ('system', 'Files', 'pryos-files', 'Files', 'thunar /root/Recovery', 'system-file-manager', False),
    ('system', 'Network', 'pryos-network', 'Network', 'nm-connection-editor', 'nm-device-wired', False),
    ('system', 'Helium', 'pryos-helium-browser', 'Helium', 'pryos-browser', 'helium', False),
    ('system', 'START HERE', 'pryos-start-here', 'START HERE', 'mousepad /root/Recovery/START-HERE.txt', 'help-about', False),
]
for folder in ('agents', 'disks', 'windows', 'system'):
    folder_dir = desktop_root / folder
    folder_dir.mkdir(parents=True, exist_ok=True)
    for stale in folder_dir.glob('*.desktop'):
        stale.unlink()
for folder, filename, menu_id, name, command, icon, terminal in entries:
    contents = f'[Desktop Entry]\nVersion=1.0\nType=Application\nName={name}\nExec={command}\nIcon={icon}\nTerminal={str(terminal).lower()}\nCategories=System;\nStartupNotify=false\n'
    menu_entry = apps / f'{menu_id}.desktop'
    menu_entry.write_text(contents)
    menu_entry.chmod(0o755)
    launcher = desktop_root / folder / f'{filename}.desktop'
    launcher.write_text(contents)
    launcher.chmod(0o755)
