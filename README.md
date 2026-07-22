# debian-janitor
A simple system cleaner tool that runs the integrity check on the package manger, pulls update and purge the unused memory.
---
# Linux System Maintenance Tool

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

* **NOTE: The cuurent version is tested on Zorin, Kali Linux and Raspberry Pi OS.**

## Installation

Clone this repository and navigate into the project directory:

```bash
git clone https://github.com
cd YOUR-REPOSITORY-NAME
```

*(Note: Add your specific compilation, execution, or script permission commands here—for example: `chmod +x script.sh`)*

## Usage

To launch the application, run the following command in your terminal:

```bash
# Example command to run your app
./run-app.sh
```

## Contributing

Contributions are welcome! If you want to improve this tool:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
