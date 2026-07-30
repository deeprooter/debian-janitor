# debian-janitor

_A simple destro cleaner tool that runs the integrity check on the package manger, pulls update and purge the unused memory._
---
## Linux System Maintenance Tool

Maintaining and keeping a Linux distribution up to date can feel overwhelming. This is especially true for Debian-based operating systems, where updates arrive almost daily and require regular attention. While standard system updates are relatively straightforward, essential maintenance tasks—like fixing a broken package manager, purging old, unused packages, and clearing system clutter—often get left behind. 

The goal of this project is to provide casual and novice users, particularly those migrating from Windows or Android, with a simple, familiar way to manage and fine-tune their Linux system using an interface similar to traditional optimization apps.

## Features

* **One-Click Updates:** Keep your system core and packages fresh effortlessly.
* **Package Repair:** Automatically fix broken dependencies and package manager locks.
* **System Purge:** Remove old kernels, unused packages, and orphan dependencies (`autoremove`).
* **Cache & Clutter Cleaner:** Free up disk space by clearing out temporary system logs and apt caches.
* **Novice-Friendly Interface:** No complex terminal commands required.

## 📋 Prerequisites

Before installing, ensure your system meets the following requirements:
* **Operating System:** Ubuntu, Debian, Linux Mint, or any Debian-based distribution.
* **Permissions:** Sudo/root access (required to manage system packages).

* **NOTE: The current version is tested on Zorin, Kali Linux and Raspberry Pi OS.**

## Installation

Download the file:```sys-cleanup-pkg.deb``` in you ``` /tmp ```directory:
```bash
cd /tmp
```

```bash
chmod +x sys-cleanup-pkg.deb
````

```bash
sudo apt install ./sys-cleanup-pkg.deb
```

Upon successful installation an icon will be added to your **show apps** section. 
Alternatively, you may find the installed utility with name **System Maintenance Tool**.

## Usage
1. Enter password for the current user
2. Make selection for the jobs and hit OK.
<img width="570" height="420" alt="image" src="https://github.com/user-attachments/assets/959ffff2-2993-4307-9f1b-8ba2f95784bd" />

Logs are shown on screen. After successful completion you shall see message with memory recovered (if job selected).

## Screenshots

<img width="1236" height="764" alt="image" src="https://github.com/user-attachments/assets/ad7934d8-45c7-4cf9-8698-1e89930c17b9" />
<img width="966" height="474" alt="Screenshot From 2026-07-29 23-02-23" src="https://github.com/user-attachments/assets/92ed2d45-d76e-45c7-ba9d-ab46c9762407" />
<img width="1192" height="1006" alt="image" src="https://github.com/user-attachments/assets/fbce63b3-453d-417b-bd0d-b9ee26e2cb2c" />
<img width="1516" height="1014" alt="image" src="https://github.com/user-attachments/assets/4c582079-7e1f-43d6-9a22-7502117c3580" />
<img width="1020" height="532" alt="image" src="https://github.com/user-attachments/assets/41186fc1-ce27-454c-85ae-ac9dc37fb10f" />


## Contributing

Contributions are welcome! If you want to improve this tool:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
